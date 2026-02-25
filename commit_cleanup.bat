@echo off
cd /d "D:\paper\IJIO_GMM_codex_en"

echo 提交清理工作到 Git...
echo.

REM 查看状态
git status --short

echo.
echo 添加变更...
git add -A

echo.
echo 创建提交...
git commit -m "chore: 清理工作空间 - 删除临时文件和时间戳文件夹

已清理项目:
- 删除 40+ 个 tmp_*.do 和 tmp_*.log 文件
- 删除 24 个时间戳文件夹 (run_YYYYMMDD_HHMMSS 格式)
- 删除测试验证文件
- 保留所有必要的代码、数据和结果文件

工作空间现在更整洁和易于管理。"

echo.
echo 验证提交...
git log --oneline -3

pause
