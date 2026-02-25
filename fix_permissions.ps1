# ============================================================================
# fix_permissions.ps1
# 目的：移除输出目录中的只读属性，确保 Stata 可以覆盖文件
# 使用方法：powershell -ExecutionPolicy Bypass -File fix_permissions.ps1
# ============================================================================

param(
    [string]$RootPath = "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "权限修复脚本" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 需要处理的目录列表
$targetDirs = @(
    "$RootPath\results\data",
    "$RootPath\results\logs",
    "$RootPath\data\work"
)

foreach ($dir in $targetDirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "`n【跳过】目录不存在: $dir" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`n【处理】$dir" -ForegroundColor Green
    
    # 统计信息
    $allFiles = Get-ChildItem -Path $dir -Recurse -File -Force -ErrorAction SilentlyContinue
    $readonlyFiles = $allFiles | Where-Object { $_.Attributes -match 'ReadOnly' }
    
    Write-Host "  总文件数: $($allFiles.Count)"
    Write-Host "  只读文件数: $($readonlyFiles.Count)"
    
    # 移除只读属性
    if ($readonlyFiles.Count -gt 0) {
        Write-Host "  移除只读属性..."
        $readonlyFiles | ForEach-Object {
            try {
                # 使用 attrib 命令移除只读属性
                & attrib -r "$($_.FullName)" 2>$null | Out-Null
                Write-Host "    ✓ $($_.Name)"
            } catch {
                Write-Host "    ✗ 失败: $($_.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  无只读文件，跳过。"
    }
    
    # 移除所有目录的只读属性
    $dirs = Get-ChildItem -Path $dir -Recurse -Directory -Force -ErrorAction SilentlyContinue
    $readonlyDirs = $dirs | Where-Object { $_.Attributes -match 'ReadOnly' }
    
    if ($readonlyDirs.Count -gt 0) {
        Write-Host "  移除只读目录属性..."
        $readonlyDirs | ForEach-Object {
            try {
                & attrib -r "$($_.FullName)" /s /d 2>$null | Out-Null
                Write-Host "    ✓ $($_.Name)/"
            } catch {
                Write-Host "    ✗ 失败: $($_.Name)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "✓ 权限修复完成" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# 验证修复
Write-Host "`n【验证】测试写入权限..." -ForegroundColor Cyan
$testDir = "$RootPath\results\data"
$testFile = "$testDir\test_permission_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

try {
    "Permission test" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item $testFile -ErrorAction SilentlyContinue
    Write-Host "✓ 可以成功写入文件" -ForegroundColor Green
} catch {
    Write-Host "✗ 写入失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n脚本执行完毕。" -ForegroundColor Cyan
