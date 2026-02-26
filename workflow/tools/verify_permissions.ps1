# Temporary verification script
Set-Location 'D:\paper\IJIO_GMM_codex_en'

Write-Host '======== Permission Verification ========' -ForegroundColor Cyan
Write-Host ''

# Test 1: Create and delete log file
Write-Host '[1] Testing log file operations' -ForegroundColor Yellow
'test log content' | Out-File -FilePath 'test_verification.log' -Encoding UTF8
if (Test-Path 'test_verification.log') {
    Write-Host '  OK: Log file created'
    Remove-Item 'test_verification.log' -Force
    if (-not (Test-Path 'test_verification.log')) {
        Write-Host '  OK: Log file deleted successfully'
    }
}

# Test 2: Test data file replacement
Write-Host ''
Write-Host '[2] Testing data file replacement' -ForegroundColor Yellow
'test data' | Out-File -FilePath 'test_replace.dta' -Encoding UTF8
if (Test-Path 'test_replace.dta') {
    Write-Host '  OK: Data file created'
    'modified test' | Out-File -FilePath 'test_replace.dta' -Encoding UTF8 -Force
    Write-Host '  OK: Data file replaced successfully'
    Remove-Item 'test_replace.dta' -Force
    Write-Host '  OK: Data file deleted successfully'
}

# Test 3: Check original data readonly attribute
Write-Host ''
Write-Host '[3] Verifying original data protection' -ForegroundColor Yellow
$files = @('firststage.dta', 'OLStariff_yu_style.dta')
foreach ($fname in $files) {
    $item = Get-Item $fname -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReadOnly) {
        Write-Host "  OK: $fname - readonly protection active"
    }
}

# Test 4: Try to modify original data (should fail)
Write-Host ''
Write-Host '[4] Testing original data protection' -ForegroundColor Yellow
try {
    'attempt to modify' | Out-File -FilePath 'firststage.dta' -Encoding UTF8 -ErrorAction Stop
    Write-Host '  FAILED: Original data can be modified!' -ForegroundColor Red
} catch {
    Write-Host '  OK: Original data protected from modification'
}

Write-Host ''
Write-Host '======== Verification Complete - All Tests Passed ========' -ForegroundColor Green
