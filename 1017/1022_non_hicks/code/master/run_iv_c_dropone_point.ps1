$root = "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
$masterDir = "$root/code/master"
$stata = "D:/AppGallery/stata18/StataMP-64.exe"
$runid = (Get-Date -Format "yyyyMMdd_HHmmssfff")

$baseG1 = @("const","llag","klag","mlag","lages","lages2q","l_ind_yr","m_ind_yr","k_ind_yr","Z_tariff","Z_HHI_post")
$baseG2 = @("const","llag","klag","mlag","lages","lages2q","l_ind_yr","k_ind_yr","m_ind_yr","Z_HHI_post")

function Run-DropOne([string]$group, [string[]]$baseSet) {
  $dropCandidates = $baseSet | Where-Object { $_ -ne "const" }
  foreach ($d in $dropCandidates) {
    $newSet = $baseSet | Where-Object { $_ -ne $d }
    $zlist = ($newSet -join " ")
    $tag = "${group}_drop_${d}"
    $dw = "$root/data/work/ivdrop_C_${tag}_$runid"
    $rl = "$root/results/logs/ivdrop_C_${tag}_$runid"
    New-Item -ItemType Directory -Force -Path $dw | Out-Null
    New-Item -ItemType Directory -Force -Path $rl | Out-Null

    $doPath = "$masterDir/tmp_ivdrop_C_$tag.do"
    $lines = @(
      "clear",
      "set more off",
      "global ROOT `"$root`"",
      "global CODE `"$root/code`"",
      "global DATA_RAW `"$root/data/raw`"",
      "global DATA_WORK `"$dw`"",
      "global RES_DATA `"$root/results/data`"",
      "global RES_LOG `"$rl`"",
      "global TARGET_GROUP `"$group`"",
      "global RUN_POINT_ONLY 1",
      "global RUN_BOOT 0",
      "global RUN_DIAG 0",
      "global ROBUST_INIT 0",
      "global IV_SET `"C`""
    )

    if ($group -eq "G1_17_19") {
      $lines += "global IV_Z_G1 `"$zlist`""
      $lines += "global IV_Z_G2 `"`""
    } else {
      $lines += "global IV_Z_G1 `"`""
      $lines += "global IV_Z_G2 `"$zlist`""
    }

    $lines += 'do "$ROOT/code/master/Master_Non_hicks.do"'
    Set-Content -Path $doPath -Value $lines -Encoding ascii

    Push-Location $masterDir
    $doAbs = Join-Path $masterDir "tmp_ivdrop_C_$tag.do"
    $cmd = '"' + $stata.Replace('/','\') + '" /e do "' + $doAbs.Replace('/','\') + '"'
    cmd /c $cmd | Out-Null
    Pop-Location

    $src = "$dw/nonhicks_points_by_group.dta"
    $dst = "$root/results/data/ivdrop_C_$tag.dta"
    if (Test-Path $src) { Copy-Item $src $dst -Force }
  }
}

Run-DropOne -group "G1_17_19" -baseSet $baseG1
Run-DropOne -group "G2_39_41" -baseSet $baseG2
