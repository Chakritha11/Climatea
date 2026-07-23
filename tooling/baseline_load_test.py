import argparse
import os
import ssl
import statistics
import threading
import time
import urllib.error
import urllib.request

DEFAULT_VUS = 100
DEFAULT_DURATION = 60


def parse_args():
    parser = argparse.ArgumentParser(
        description='Baseline load test runner. Sends concurrent GET requests and reports RPS and response times.'
    )
    parser.add_argument('--base-url', help='Base URL for the target service', default=os.environ.get('BASE_URL'))
    parser.add_argument('--endpoint', help='Request path for the target service', default=os.environ.get('ENDPOINT', '/'))
    parser.add_argument('--vus', type=int, help='Number of virtual users', default=int(os.environ.get('VUS', DEFAULT_VUS)))
    parser.add_argument('--duration', type=int, help='Duration in seconds', default=int(os.environ.get('DURATION', DEFAULT_DURATION)))
    parser.add_argument('--ramp-up', type=int, help='Ramp-up time in seconds', default=int(os.environ.get('RAMP_UP', 0)))
    parser.add_argument('--target-rps', type=float, help='Target requests per second', default=float(os.environ.get('TARGET_RPS', 0)))
    parser.add_argument('--timeout', type=int, help='HTTP request timeout in seconds', default=15)
    parser.add_argument('--silent-errors', action='store_true', help='Suppress repeated error logging')
    return parser.parse_args()


def build_rate_limiter(target_rps):
    if not target_rps or target_rps <= 0:
        return None

    lock = threading.Lock()
    interval = 1.0 / target_rps
    state = {'next_time': time.monotonic()}

    def wait_for_turn():
        with lock:
            now = time.monotonic()
            due = max(state['next_time'] + interval, now)
            state['next_time'] = due
        sleep_time = due - now
        if sleep_time > 0:
            time.sleep(sleep_time)

    return wait_for_turn


class Metrics:
    def __init__(self):
        self.lock = threading.Lock()
        self.durations = []
        self.status_codes = {}
        self.failures = 0
        self.requests = 0

    def add(self, duration_ms, status):
        with self.lock:
            self.requested(duration_ms, status)

    def requested(self, duration_ms, status):
        self.requests += 1
        self.durations.append(duration_ms)
        self.status_codes[status] = self.status_codes.get(status, 0) + 1

    def fail(self):
        with self.lock:
            self.failures += 1
            self.requests += 1


def build_url(base_url, endpoint):
    if not base_url:
        raise ValueError('Missing base URL. Use --base-url or set BASE_URL.')

    normalized = base_url.rstrip('/')
    path = endpoint or '/'
    if not path.startswith('/'):
        path = '/' + path
    return normalized + path


def worker(worker_id, url, stop_at, metrics, timeout, silent_errors, ramp_up, vus, rate_limiter):
    ctx = ssl.create_default_context()
    last_error = None

    if ramp_up and ramp_up > 0:
        initial_sleep = (worker_id - 1) * (ramp_up / max(1, vus))
        if initial_sleep > 0:
            time.sleep(initial_sleep)

    while time.monotonic() < stop_at:
        if rate_limiter:
            rate_limiter()

        request_start = time.perf_counter()
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'baseline-load-test/1.0'})
            with urllib.request.urlopen(req, timeout=timeout, context=ctx) as response:
                status = response.getcode()
                response.read(1)
            request_elapsed = (time.perf_counter() - request_start) * 1000
            metrics.add(request_elapsed, status)
        except urllib.error.HTTPError as exc:
            request_elapsed = (time.perf_counter() - request_start) * 1000
            metrics.add(request_elapsed, exc.code)
            if not silent_errors:
                print(f'[VU {worker_id}] HTTP {exc.code}: {exc.reason}')
        except urllib.error.URLError as exc:
            metrics.fail()
            if not silent_errors and str(exc) != last_error:
                print(f'[VU {worker_id}] request failed: {exc}')
                last_error = str(exc)
        except Exception as exc:
            metrics.fail()
            if not silent_errors and str(exc) != last_error:
                print(f'[VU {worker_id}] unexpected error: {exc}')
                last_error = str(exc)


def summarize(metrics, total_duration):
    print('\n=== Load Test Summary ===')
    print(f'Total duration: {total_duration:.2f}s')
    print(f'Total requests: {metrics.requests}')
    print(f'Successful requests: {metrics.requests - metrics.failures}')
    print(f'Failed requests: {metrics.failures}')

    if total_duration > 0:
        print(f'Requests per second (RPS): {metrics.requests / total_duration:.2f}')

    if metrics.durations:
        durations = sorted(metrics.durations)
        print(f'Average response time: {statistics.mean(durations):.1f} ms')
        print(f'Min response time: {durations[0]:.1f} ms')
        print(f'Max response time: {durations[-1]:.1f} ms')
        for percentile in (50, 90, 95, 99):
            index = min(len(durations) - 1, int(len(durations) * percentile / 100) - 1)
            index = max(0, index)
            print(f'p{percentile}: {durations[index]:.1f} ms')
    else:
        print('No successful response timings recorded.')

    print('\nStatus code distribution:')
    for status, count in sorted(metrics.status_codes.items()):
        print(f'  {status}: {count}')


def main():
    args = parse_args()
    target_url = build_url(args.base_url, args.endpoint)
    print(f'Baseline load test target: {target_url}')
    print(f'VUs: {args.vus}, duration: {args.duration}s')

    metrics = Metrics()
    rate_limiter = build_rate_limiter(args.target_rps)
    stop_at = time.monotonic() + args.duration
    threads = []

    for i in range(args.vus):
        thread = threading.Thread(
            target=worker,
            args=(
                i + 1,
                target_url,
                stop_at,
                metrics,
                args.timeout,
                args.silent_errors,
                args.ramp_up,
                args.vus,
                rate_limiter,
            ),
            daemon=True,
        )
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join(timeout=max(0, stop_at - time.monotonic() + 5))

    actual_duration = args.duration
    summarize(metrics, actual_duration)


if __name__ == '__main__':
    main()
