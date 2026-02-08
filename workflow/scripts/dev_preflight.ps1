![1770546047211](image/dev_preflight/1770546047211.png)![1770546050799](image/dev_preflight/1770546050799.png)![1770546060226](image/dev_preflight/1770546060226.png)param(
    [string]$WorkspaceRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"

Write-Host "== Dev Preflight ==" -ForegroundColor Cyan

$cwd = (Get-Location).Path
Write-Host "Current Dir  : $cwd"
Write-Host "Workspace Dir: $WorkspaceRoot"

if (-not $cwd.StartsWith($WorkspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "[ERROR] Current directory is outside the workspace." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Workspace check passed." -ForegroundColor Green

cmd /c "git rev-parse --is-inside-work-tree >nul 2>nul"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Current directory is not a git repository." -ForegroundColor Yellow
    Write-Host "Optional init steps:"
    Write-Host "  git init"
    Write-Host "  git add ."
    Write-Host "  git commit -m `"chore: initial snapshot`""
    Write-Host ""
    Write-Host "Recommended: Review first, then apply changes."
    exit 0
}

Write-Host "[OK] Git repository detected." -ForegroundColor Green

$branch = git branch --show-current
Write-Host "Branch: $branch"

Write-Host ""
Write-Host "-- git status --"
git status --short

Write-Host ""
Write-Host "-- review commands (recommended) --"
Write-Host '  rg -n "<keyword>"'
Write-Host "  git diff -- <file>"
Write-Host "  git diff --cached -- <file>"

Write-Host ""
Write-Host "[Checklist]"
Write-Host "  1) Review first, then apply"
Write-Host "  2) Use small commits for easy rollback"
Write-Host "  3) Prompt must include: Only modify files in this workspace; do not touch anything outside."
