import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 100,
  duration: '1m',
  thresholds: {
    'http_req_duration': ['p(95)<1000', 'p(99)<1500'],
    'http_req_failed': ['rate<0.01'],
  },
};

// Set the target URL via environment variable when running the test.
// Example: BASE_URL=https://your-api.example.com k6 run tooling/baseline_load_test.js
const BASE_URL = __ENV.BASE_URL || 'https://your-api.example.com';
const ENDPOINT = __ENV.ENDPOINT || '/';

export default function () {
  const url = `${BASE_URL.replace(/\/$/, '')}${ENDPOINT.startsWith('/') ? ENDPOINT : `/${ENDPOINT}`}`;
  const res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  // If you want a bit more realistic pacing, uncomment the line below.
  // sleep(1);
}
