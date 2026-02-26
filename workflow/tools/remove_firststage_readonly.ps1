# Remove readonly from firststage.dta
Set-Location 'D:\paper\IJIO_GMM_codex_en'

Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host '  Updating firststage.dta permissions                            ' -ForegroundColor Cyan
Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host ''

if (Test-Path 'firststage.dta') {
    $file = Get-Item 'firststage.dta' -Force
    Write-Host "Current attributes: $($file.Attributes)"
    
    # Remove readonly
    $file.Attributes = $file.Attributes -band -bnot [IO.FileAttributes]::ReadOnly
    Write-Host "Updated attributes: $($file.Attributes)"
    Write-Host ''
    Write-Host 'OK: firststage.dta is now writable (can be replaced/deleted)' -ForegroundColor Green
} else {
    Write-Host 'File not found' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '==================================================================' -ForegroundColor Cyan
