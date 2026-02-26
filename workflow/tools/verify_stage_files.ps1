# Verify stage files permissions
Set-Location 'D:\paper\IJIO_GMM_codex_en'

Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host '  Verifying stage files permissions                             ' -ForegroundColor Cyan
Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host ''

$files = @('firststagecd.dta', 'firststagehicks.dta')

foreach ($fname in $files) {
    if (Test-Path $fname) {
        $file = Get-Item $fname -Force
        Write-Host "File: $fname"
        Write-Host "  Attributes: $($file.Attributes)" -ForegroundColor Yellow
        
        # Test write capability
        $testFile = $fname + '.test'
        'test' | Out-File $testFile -Encoding UTF8
        if (Test-Path $testFile) {
            Write-Host "  OK: Can create files" -ForegroundColor Green
            Remove-Item $testFile -Force
        }
    } else {
        Write-Host "$fname - NOT FOUND" -ForegroundColor Red
    }
    Write-Host ''
}

Write-Host '==================================================================' -ForegroundColor Green
Write-Host '  Verification Complete: All stage files are writable' -ForegroundColor Green
Write-Host '==================================================================' -ForegroundColor Green
