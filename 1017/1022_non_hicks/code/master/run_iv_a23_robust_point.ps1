$root = "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
$masterDir = "$root/code/master"
$stata = "D:/AppGallery/stata18/StataMP-64.exe"
$sets = @("A2","A3")
$runid = (Get-Date -Format "yyyyMMdd_HHmmssfff")

foreach ($s in $sets) {
  $dw = "$root/data/work/ivscreen_${s}_robust_$runid"
  $rl = "$root/results/logs/ivscreen_${s}_robust_$runid"
  New-Item -ItemType Directory -Force -Path $dw | Out-Null
  New-Item -ItemType Directory -Force -Path $rl | Out-Null

  $doPath = "$masterDir/tmp_ivscreen_${s}_robust.do"
@"
clear
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
global ROBUST_INIT 1
global IV_SET "$s"
global IV_Z_G1 ""
global IV_Z_G2 ""
do "$ROOT/code/master/Master_Non_hicks.do"
"@ | Out-File -FilePath $doPath -Encoding ascii

  Push-Location $masterDir
  & $stata /e do "tmp_ivscreen_${s}_robust.do"
  Pop-Location

  $src = "$dw/nonhicks_points_by_group.dta"
  $dst = "$root/results/data/ivscreen_points_${s}_robust.dta"
  if (Test-Path $src) { Copy-Item $src $dst -Force }
}
