param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [int]$MaxFiles = 5,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 当前目录不是 git 仓库，无法提交。" -ForegroundColor Red
    exit 1
}

$staged = git diff --cached --name-only
if (-not $staged) {
    Write-Host "[ERROR] 暂存区为空。先执行 git add 再提交。" -ForegroundColor Red
    exit 1
}

$count = ($staged | Measure-Object -Line).Lines
Write-Host "Staged files: $count"
$staged

if ($count -gt $MaxFiles -and -not $Force) {
    Write-Host "[WARN] 暂存文件数超过阈值 ($MaxFiles)，建议小步提交。" -ForegroundColor Yellow
    Write-Host "如确认一次提交，请加 -Force。"
    exit 1
}

git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 提交失败。" -ForegroundColor Red
    exit 1
}

$hash = git rev-parse --short HEAD
Write-Host "[OK] 提交完成: $hash" -ForegroundColor Green
