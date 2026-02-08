$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Join-Path $root "config\tools.ps1"
if (Test-Path $config) {
    . $config
}

$runPython = $env:RUN_PYTHON -eq "1"

$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $root "output\runs\$runId"

$null = New-Item -ItemType Directory -Force -Path $runDir
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root "output\logs")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root "output\tables")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root "output\figures")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root "data\raw")
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root "data\processed")

$runLog = Join-Path $runDir "run.log"

function Write-RunLog {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    $line | Add-Content -Path $runLog -Encoding UTF8
    Write-Host $line
}

function Resolve-Exe {
    param([string]$Exe)
    if (-not $Exe) { return $null }
    $cmd = Get-Command $Exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }
    if (Test-Path $Exe) { return $Exe }
    return $null
}

function Invoke-Tool {
    param(
        [string]$Name,
        [string]$Exe,
        [string[]]$Args,
        [string]$LogFile
    )
    $resolved = Resolve-Exe $Exe
    if (-not $resolved) {
        Write-RunLog "SKIP $Name (executable not configured or not found)"
        return
    }
    Write-RunLog "RUN  $Name"
    $output = & $resolved @Args 2>&1
    $output | Set-Content -Path $LogFile -Encoding UTF8
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        Write-RunLog "FAIL $Name (exit $exit)"
    } else {
        Write-RunLog "OK   $Name"
    }
}

# Stata
$stataDo = Join-Path $root "src\stata\10_analysis.do"
if (Test-Path $stataDo) {
    $stataArgs = @()
    if ($env:STATA_ARGS) { $stataArgs += $env:STATA_ARGS -split ' ' }
    $stataArgs += @("do", $stataDo)
    Invoke-Tool "Stata" $env:STATA_EXE $stataArgs (Join-Path $runDir "stata.log")
} else {
    Write-RunLog "SKIP Stata (missing $stataDo)"
}

# Matlab
$matlabFile = Join-Path $root "src\matlab\10_analysis.m"
if (Test-Path $matlabFile) {
    $matlabArgs = @()
    if ($env:MATLAB_ARGS) { $matlabArgs += $env:MATLAB_ARGS -split ' ' }
    $matlabCmd = "run('$matlabFile');"
    $matlabArgs += $matlabCmd
    Invoke-Tool "Matlab" $env:MATLAB_EXE $matlabArgs (Join-Path $runDir "matlab.log")
} else {
    Write-RunLog "SKIP Matlab (missing $matlabFile)"
}

# Python
$pyFile = Join-Path $root "src\python\10_analysis.py"
if (-not $runPython) {
    Write-RunLog "SKIP Python (disabled)"
} elseif (Test-Path $pyFile) {
    Invoke-Tool "Python" $env:PYTHON_EXE @($pyFile) (Join-Path $runDir "python.log")
} else {
    Write-RunLog "SKIP Python (missing $pyFile)"
}

# Gauss
$gaussFile = Join-Path $root "src\gauss\10_analysis.src"
if (Test-Path $gaussFile) {
    $gaussArgs = @()
    if ($env:GAUSS_ARGS) { $gaussArgs += $env:GAUSS_ARGS -split ' ' }
    $gaussArgs += $gaussFile
    Invoke-Tool "Gauss" $env:GAUSS_EXE $gaussArgs (Join-Path $runDir "gauss.log")
} else {
    Write-RunLog "SKIP Gauss (missing $gaussFile)"
}
