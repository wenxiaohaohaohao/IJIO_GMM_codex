# ============================================================================
# protect_original_data.ps1
# Purpose: Set original data files to readonly to prevent accidental changes
# Usage: powershell -ExecutionPolicy Bypass -File protect_original_data.ps1
# ============================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Protecting original data files (setting to readonly)          " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$RootPath = "D:\paper\IJIO_GMM_codex_en"

$originalDataFiles = @(
    "Brandt-Rawski investment deflator.dta",
    "OLStariff_yu_style.dta",
    "processing_vars_yu_style.dta"
)

$protectedCount = 0
$notFoundCount = 0

Write-Host "[1] Setting original data files to readonly..." -ForegroundColor Yellow
Write-Host ""

foreach ($fileName in $originalDataFiles) {
    $filePath = Join-Path $RootPath $fileName
    
    if (Test-Path $filePath) {
        try {
            $file = Get-Item $filePath -Force
            $file.Attributes = $file.Attributes -bor [IO.FileAttributes]::ReadOnly
            Write-Host "  OK: $fileName" -ForegroundColor Green
            $protectedCount++
        } catch {
            Write-Host "  ERROR: $fileName - $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  NOT FOUND: $fileName" -ForegroundColor Yellow
        $notFoundCount++
    }
}

Write-Host ""
Write-Host "[2] Protection summary:" -ForegroundColor Yellow
Write-Host "  - Protected: $protectedCount files" -ForegroundColor Green
Write-Host "  - Not found: $notFoundCount files" -ForegroundColor Yellow
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Original data protection completed!                            " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
