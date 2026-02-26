# Remove readonly from firststagecd.dta and firststagehicks.dta
Set-Location 'D:\paper\IJIO_GMM_codex_en'

Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host '  Removing readonly attributes from stage files                  ' -ForegroundColor Cyan
Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host ''

$files = @('firststagecd.dta', 'firststagehicks.dta')

foreach ($fname in $files) {
    if (Test-Path $fname) {
        $file = Get-Item $fname -Force
        Write-Host "Processing: $fname"
        Write-Host "  Current attributes: $($file.Attributes)"
        
        # Remove readonly
        $file.Attributes = $file.Attributes -band -bnot [IO.FileAttributes]::ReadOnly
        Write-Host "  Updated attributes: $($file.Attributes)"
        Write-Host "  OK: $fname is now writable" -ForegroundColor Green
    } else {
        Write-Host "$fname - NOT FOUND" -ForegroundColor Yellow
    }
    Write-Host ''
}

Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host '  All stage files updated successfully' -ForegroundColor Green
Write-Host '==================================================================' -ForegroundColor Cyan
