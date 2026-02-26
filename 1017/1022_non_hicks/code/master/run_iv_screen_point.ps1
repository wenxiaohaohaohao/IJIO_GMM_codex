$root = "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
$masterDir = "$root/code/master"
$stata = "D:/AppGallery/stata18/StataMP-64.exe"
$sets = @("A","B","C","A1","A2","A3")

foreach ($s in $sets) {
    $dw = "$root/data/work/ivscreen_$s"
    $rd = "$root/results/data"
    $rl = "$root/results/logs/ivscreen_$s"
    New-Item -ItemType Directory -Force -Path $dw | Out-Null
    New-Item -ItemType Directory -Force -Path $rd | Out-Null
    New-Item -ItemType Directory -Force -Path $rl | Out-Null

    $doPath = "$masterDir/tmp_ivscreen_$s.do"
@"
clear all
set more off
global ROOT "$root"
global CODE "$root/code"
global DATA_RAW "$root/data/raw"
global DATA_WORK "$dw"
global RES_DATA "$root/results/data"
global RES_LOG "$rl"
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 0
global IV_SET "$s"
do "`$ROOT/code/master/run_step1_point_diag.do"
"@ | Out-File -FilePath $doPath -Encoding ascii

    Push-Location $masterDir
    & $stata /e do "tmp_ivscreen_$s.do"
    Pop-Location

    $src = "$dw/nonhicks_points_by_group.dta"
    $dst = "$rd/ivscreen_points_$s.dta"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Force
    }
}
