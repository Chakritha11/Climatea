#!/bin/bash
# Generate Flutter test report locally

set -e

echo "🧪 Generating Flutter test results..."
flutter test --machine 2>&1 | tee test_results.json

echo ""
echo "📊 Converting to Excel report..."
python3 tooling/convert_flutter_test_machine_to_xlsx.py test_results.json test_report.xlsx

echo ""
echo "✅ Report generated: test_report.xlsx"
echo "📁 You can now download this file or view it in Excel/LibreOffice"
