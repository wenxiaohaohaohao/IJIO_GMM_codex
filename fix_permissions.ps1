# ============================================================================
# fix_permissions.ps1
# 鐩殑锛氱Щ闄よ緭鍑虹洰褰曚腑鐨勫彧璇诲睘鎬э紝纭繚 Stata 鍙互瑕嗙洊鏂囦欢
# 浣跨敤鏂规硶锛歱owershell -ExecutionPolicy Bypass -File fix_permissions.ps1
# ============================================================================

param(
    [string]$RootPath = "D:\paper\IJIO_GMM_codex_en\methods\non_hicks"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "鏉冮檺淇鑴氭湰" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 闇€瑕佸鐞嗙殑鐩綍鍒楄〃
$targetDirs = @(
    "$RootPath\results\data",
    "$RootPath\results\logs",
    "$RootPath\data\work"
)

foreach ($dir in $targetDirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "`n銆愯烦杩囥€戠洰褰曚笉瀛樺湪: $dir" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`n銆愬鐞嗐€?dir" -ForegroundColor Green
    
    # 缁熻淇℃伅
    $allFiles = Get-ChildItem -Path $dir -Recurse -File -Force -ErrorAction SilentlyContinue
    $readonlyFiles = $allFiles | Where-Object { $_.Attributes -match 'ReadOnly' }
    
    Write-Host "  鎬绘枃浠舵暟: $($allFiles.Count)"
    Write-Host "  鍙鏂囦欢鏁? $($readonlyFiles.Count)"
    
    # 绉婚櫎鍙灞炴€?
    if ($readonlyFiles.Count -gt 0) {
        Write-Host "  绉婚櫎鍙灞炴€?.."
        $readonlyFiles | ForEach-Object {
            try {
                # 浣跨敤 attrib 鍛戒护绉婚櫎鍙灞炴€?
                & attrib -r "$($_.FullName)" 2>$null | Out-Null
                Write-Host "    鉁?$($_.Name)"
            } catch {
                Write-Host "    鉁?澶辫触: $($_.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  鏃犲彧璇绘枃浠讹紝璺宠繃銆?
    }
    
    # 绉婚櫎鎵€鏈夌洰褰曠殑鍙灞炴€?
    $dirs = Get-ChildItem -Path $dir -Recurse -Directory -Force -ErrorAction SilentlyContinue
    $readonlyDirs = $dirs | Where-Object { $_.Attributes -match 'ReadOnly' }
    
    if ($readonlyDirs.Count -gt 0) {
        Write-Host "  绉婚櫎鍙鐩綍灞炴€?.."
        $readonlyDirs | ForEach-Object {
            try {
                & attrib -r "$($_.FullName)" /s /d 2>$null | Out-Null
                Write-Host "    鉁?$($_.Name)/"
            } catch {
                Write-Host "    鉁?澶辫触: $($_.Name)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "鉁?鏉冮檺淇瀹屾垚" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# 楠岃瘉淇
Write-Host "`n銆愰獙璇併€戞祴璇曞啓鍏ユ潈闄?.." -ForegroundColor Cyan
$testDir = "$RootPath\results\data"
$testFile = "$testDir\test_permission_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

try {
    "Permission test" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item $testFile -ErrorAction SilentlyContinue
    Write-Host "鉁?鍙互鎴愬姛鍐欏叆鏂囦欢" -ForegroundColor Green
} catch {
    Write-Host "鉁?鍐欏叆澶辫触: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n鑴氭湰鎵ц瀹屾瘯銆? -ForegroundColor Cyan

