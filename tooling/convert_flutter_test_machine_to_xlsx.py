import json
import sys
from openpyxl import Workbook
from datetime import datetime

def parse_machine(file_path):
    tests = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            if not content:
                return tests
            
            # Try parsing as single JSON object first
            try:
                obj = json.loads(content)
                if isinstance(obj, dict) and obj.get('type'):
                    tests.append(obj)
                    return tests
            except json.JSONDecodeError:
                pass
            
            # Parse as newline-delimited JSON
            for line in content.split('\n'):
                if not line.strip():
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if obj.get('type') in ('testDone', 'testStart', 'testError', 'start', 'done'):
                    tests.append(obj)
    except Exception as e:
        print(f'Warning: Error reading {file_path}: {e}')
    
    return tests

def write_xlsx(events, out_path):
    wb = Workbook()
    ws = wb.active
    ws.title = 'flutter_tests'
    ws.append(['Type', 'Time (ms)', 'Test Name', 'Result', 'Skipped', 'Hidden', 'Message'])

    if not events:
        ws.append(['No test events', '', '', '', '', '', 'No tests were run or results were empty'])
    else:
        for ev in events:
            t = ev.get('type', '')
            time = ev.get('time', '')
            
            # Extract test name from nested test object
            test_obj = ev.get('test', {})
            if isinstance(test_obj, dict):
                name = test_obj.get('name', '')
            else:
                name = str(test_obj) if test_obj else ''
            
            result = ev.get('result', '')
            skipped = ev.get('skipped', '')
            hidden = ev.get('hidden', '')
            message = ''
            if ev.get('type') == 'testError':
                message = ev.get('error', '')
            elif ev.get('type') == 'print':
                message = ev.get('message', '')
            
            ws.append([t, time, name, result, skipped, hidden, message])

    wb.save(out_path)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: convert_flutter_test_machine_to_xlsx.py input.json output.xlsx')
        sys.exit(2)
    events = parse_machine(sys.argv[1])
    write_xlsx(events, sys.argv[2])
    print(f'Wrote {sys.argv[2]} with {len(events)} event(s)')
