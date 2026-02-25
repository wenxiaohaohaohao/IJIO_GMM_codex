@echo off
REM ============================================================================
REM fix_permissions.bat
REM 目的：移除输出目录中的只读属性
REM ============================================================================

echo ============================================
echo 权限修复脚本
echo ============================================

cd /d "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks"

echo.
echo 【处理】results/data
attrib -r "results\data" /s /d
attrib -r "results\data\*.dta" /s

echo.
echo 【处理】results/logs
attrib -r "results\logs" /s /d
attrib -r "results\logs\*.log" /s

echo.
echo 【处理】data/work
attrib -r "data\work" /s /d
attrib -r "data\work\*.dta" /s

echo.
echo ============================================
echo 权限修复完成
echo ============================================

REM 验证修复
echo.
echo 【验证】测试写入权限...
cd "results\data"
(
    echo Permission test
) > test_permission.txt

if exist test_permission.txt (
    echo 成功：可以写入文件
    del test_permission.txt
) else (
    echo 失败：无法写入文件
)

pause
