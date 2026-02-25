@echo off
REM ============================================================================
REM test_permissions.bat
REM 目的：测试权限修复的效果
REM ============================================================================

setlocal enabledelayedexpansion

echo ============================================
echo 权限修复效果测试
echo ============================================
echo.

cd /d "D:\paper\IJIO_GMM_codex_en"

REM 测试 1：results/data
echo 【测试1】results/data
cd /d "1017\1022_non_hicks\results\data"
echo test > test_write_temp.txt
if exist test_write_temp.txt (
    echo   成功：可以创建新文件
    del test_write_temp.txt
    echo   成功：可以删除文件
) else (
    echo   失败：无法创建文件
)
echo.

REM 测试2：results/logs
echo 【测试2】results/logs
cd /d "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\results\logs"
echo test >> test_write_temp.log
if exist test_write_temp.log (
    echo   成功：可以创建新文件
    del test_write_temp.log
) else (
    echo   失败：无法创建文件
)
echo.

REM 测试3：data/work
echo 【测试3】data/work
cd /d "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\data\work"
echo test > test_write_temp.txt
if exist test_write_temp.txt (
    echo   成功：可以创建新文件
    del test_write_temp.txt
) else (
    echo   失败：无法创建文件
)
echo.

echo ============================================
echo 权限验证完成
echo ============================================

cd /d "D:\paper\IJIO_GMM_codex_en"
