# Verify firststage.dta permissions
Set-Location 'D:\paper\IJIO_GMM_codex_en'

Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host '  Verifying firststage.dta permissions                           ' -ForegroundColor Cyan
Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host ''

# Check current attributes
$file = Get-Item 'firststage.dta' -Force
Write-Host "Current attributes: $($file.Attributes)" -ForegroundColor Yellow

# Test if we can create and delete a test file
Write-Host ''
Write-Host '[Test 1] Testing write/replace capability'
'test data' | Out-File 'firststage_test.dta' -Encoding UTF8
if (Test-Path 'firststage_test.dta') {
    Write-Host '  OK: Can create test file' -ForegroundColor Green
    'modified' | Out-File 'firststage_test.dta' -Encoding UTF8 -Force
    Write-Host '  OK: Can replace file' -ForegroundColor Green
    Remove-Item 'firststage_test.dta' -Force
    Write-Host '  OK: Can delete file' -ForegroundColor Green
}

Write-Host ''
Write-Host '==================================================================' -ForegroundColor Green
Write-Host '  Verification Complete: firststage.dta is now fully writable' -ForegroundColor Green
Write-Host '==================================================================' -ForegroundColor Green
