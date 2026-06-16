# Generate Flutter test report locally (Windows PowerShell)

Write-Host "🧪 Generating Flutter test results..." -ForegroundColor Cyan
flutter test --machine 2>&1 | Tee-Object -FilePath test_results.json

Write-Host ""
Write-Host "📊 Converting to Excel report..." -ForegroundColor Cyan

$pythonPath = "C:\Users\chakr\AppData\Local\Programs\Python\Python313\python.exe"
if (-not (Test-Path $pythonPath)) {
    $pythonPath = "C:\Users\chakr\AppData\Local\Programs\Python\Python311\python.exe"
}

if (-not (Test-Path $pythonPath)) {
    Write-Host "❌ Python not found. Please install Python or specify the path." -ForegroundColor Red
    exit 1
}

& $pythonPath tooling/convert_flutter_test_machine_to_xlsx.py test_results.json test_report.xlsx

Write-Host ""
Write-Host "✅ Report generated: test_report.xlsx" -ForegroundColor Green
Write-Host "📁 You can now download this file or view it in Excel" -ForegroundColor Green
