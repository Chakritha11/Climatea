import json
import sys
from openpyxl import Workbook

def parse_machine(file_path):
    tests = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                obj = json.loads(line)
            except Exception:
                continue
            if obj.get('type') == 'testDone' or obj.get('type') == 'testStart' or obj.get('type') == 'testError':
                tests.append(obj)
    return tests

def write_xlsx(events, out_path):
    wb = Workbook()
    ws = wb.active
    ws.title = 'flutter_tests'
    ws.append(['event', 'time', 'test', 'result', 'skipped', 'hidden', 'message'])

    for ev in events:
        t = ev.get('type')
        time = ev.get('time')
        name = ev.get('test', '')
        result = ev.get('result', '')
        skipped = ev.get('skipped', '')
        hidden = ev.get('hidden', '')
        message = ''
        if ev.get('type') == 'testError':
            message = ev.get('error', '')
        ws.append([t, time, name, result, skipped, hidden, message])

    wb.save(out_path)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: convert_flutter_test_machine_to_xlsx.py input.json output.xlsx')
        sys.exit(2)
    events = parse_machine(sys.argv[1])
    write_xlsx(events, sys.argv[2])
    print('Wrote', sys.argv[2])
