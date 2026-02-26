# ============================================================================
# reset_permissions_comprehensive.ps1
# Purpose: Remove delete restrictions from intermediate files
# Usage: powershell -ExecutionPolicy Bypass -File reset_permissions_comprehensive.ps1
# ============================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Removing delete restrictions from workspace files" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$RootPath = "D:\paper\IJIO_GMM_codex_en"

Write-Host "[1] Scanning for readonly files..." -ForegroundColor Yellow

$allReadOnlyFiles = @()
try {
    $allReadOnlyFiles = Get-ChildItem -Path $RootPath -Recurse -File -Force -ErrorAction SilentlyContinue | `
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReadOnly }
} catch {
    Write-Host "  Warning during scan: $_" -ForegroundColor Yellow
}

Write-Host "  Found $($allReadOnlyFiles.Count) readonly files" -ForegroundColor Green
Write-Host ""

if ($allReadOnlyFiles.Count -eq 0) {
    Write-Host "OK: No readonly files. Workspace permissions are normal." -ForegroundColor Green
    Exit 0
}

# Files to keep protected (original data)
$protectedFiles = @(
    "Brandt-Rawski investment deflator.dta",
    "firststage.dta",
    "firststagecd.dta", 
    "firststagehicks.dta",
    "OLStariff_yu_style.dta",
    "processing_vars_yu_style.dta"
)

function Should-ProtectFile {
    param([string]$FilePath, [string]$FileName)
    
    foreach ($protectedName in $protectedFiles) {
        if ($FileName -eq $protectedName) {
            return $true
        }
    }
    
    if ($FilePath -like "*guanshuishuju*" -or $FilePath -like "*\*") {
        if ($FileName.EndsWith(".dta")) {
            if ($FilePath -like "*guanshuishuju*") {
                return $true
            }
        }
    }
    
    return $false
}

$toUnlock = @()
$toKeepLocked = @()

foreach ($file in $allReadOnlyFiles) {
    if (Should-ProtectFile $file.FullName $file.Name) {
        $toKeepLocked += $file
    } else {
        $toUnlock += $file
    }
}

Write-Host "[2] File classification:" -ForegroundColor Yellow
Write-Host "  - Keep protected (original data): $($toKeepLocked.Count) files" -ForegroundColor Green
Write-Host "  - Unlock (intermediate products): $($toUnlock.Count) files" -ForegroundColor Cyan
Write-Host ""

if ($toKeepLocked.Count -gt 0) {
    Write-Host "  Protected files (staying readonly):" -ForegroundColor Green
    $toKeepLocked | Select -First 10 | ForEach-Object { 
        $rel = $_.FullName.Replace($RootPath, "").TrimStart("\")
        Write-Host "    - $rel" -ForegroundColor DarkGreen 
    }
    if ($toKeepLocked.Count -gt 10) {
        Write-Host "    ... and more" -ForegroundColor DarkGreen
    }
    Write-Host ""
}

if ($toUnlock.Count -gt 0) {
    Write-Host "[3] Removing readonly attributes..." -ForegroundColor Yellow
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($file in $toUnlock) {
        try {
            $relativePath = $file.FullName.Replace($RootPath, "").TrimStart("\")
            $file.Attributes = $file.Attributes -band -bnot [IO.FileAttributes]::ReadOnly
            Write-Host "  OK: $relativePath" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host "  ERROR: $($file.Name)" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host ""
    Write-Host "  Results: $successCount OK, $errorCount failed" -ForegroundColor Yellow
} else {
    Write-Host "[3] All files are correctly classified." -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Permission reset completed!" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now:" -ForegroundColor Yellow
Write-Host "  - Replace and delete intermediate files in your code" -ForegroundColor White
Write-Host "  - Original data files remain protected" -ForegroundColor White
