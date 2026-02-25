@echo off
REM ============================================================================
REM cleanup_workspace.bat
REM 目的：清理临时文件和时间戳文件夹
REM ============================================================================

setlocal enabledelayedexpansion

cd /d "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks"

echo ============================================
echo 清理工作开始
echo ============================================
echo.

REM 1. 删除测试验证文件
echo 【1】删除测试验证文件...
if exist "results\data\test_write_verification.txt" (
    del "results\data\test_write_verification.txt"
    echo   成功删除: test_write_verification.txt
)
if exist "results\logs\test_log_verification.log" (
    del "results\logs\test_log_verification.log"
    echo   成功删除: test_log_verification.log
)
if exist "data\work\test_data_verification.txt" (
    del "data\work\test_data_verification.txt"
    echo   成功删除: test_data_verification.txt
)
echo.

REM 2. 删除时间戳文件夹 (results/data)
echo 【2】删除时间戳文件夹 (results/data)...
for /d %%d in (results\data\run_20260224_*) do (
    rmdir /s /q "%%d"
    echo   删除: %%~nxd
)
echo.

REM 3. 删除时间戳文件夹 (results/logs)
echo 【3】删除时间戳文件夹 (results/logs)...
for /d %%d in (results\logs\run_20260224_*) do (
    rmdir /s /q "%%d"
    echo   删除: %%~nxd
)
echo.

REM 4. 删除时间戳文件夹 (data/work)
echo 【4】删除时间戳文件夹 (data/work)...
for /d %%d in (data\work\run_20260224_*) do (
    rmdir /s /q "%%d"
    echo   删除: %%~nxd
)
echo.

REM 5. 删除临时 Stata 脚本
echo 【5】删除临时 Stata 脚本和日志...
for %%f in (tmp_*.do tmp_*.log tmp_*.txt) do (
    if exist "%%f" (
        del "%%f"
        echo   删除: %%f
    )
)
echo.

echo ============================================
echo 清理完成
echo ============================================
echo.
echo 验证清理结果:
dir /b tmp_*.do tmp_*.log tmp_*.txt 2>nul | find /c /v "" >nul
if errorlevel 1 (
    echo   ✓ 所有临时文件已删除
) else (
    echo   ⚠ 仍有临时文件存在
)

pause
