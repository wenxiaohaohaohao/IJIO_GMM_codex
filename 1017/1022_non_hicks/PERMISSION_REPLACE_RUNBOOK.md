# Permission and Replace Runbook

Last updated: 2026-02-26

## 1) Goal
Unify all file overwrite operations in the main run chain to direct `replace`.

Because permissions for generated artifacts are now reset and verified, direct replace is the project standard.

## 2) Main-code scope covered
- `1017/1022_non_hicks/code/master/Master_Non_hicks.do`
- `1017/1022_non_hicks/code/master/run_iv_screen_point.do`
- `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do`

## 3) Permission scripts (from 权限管理说明.md)
Scripts location:
- `workflow/tools/reset_permissions_comprehensive.ps1`
- `workflow/tools/protect_original_data.ps1`
- `workflow/tools/verify_permissions.ps1`

Run order when r(608) appears:
1. Reset generated-file permissions
```powershell
powershell -ExecutionPolicy Bypass -File workflow\tools\reset_permissions_comprehensive.ps1
```
2. Re-protect original data
```powershell
powershell -ExecutionPolicy Bypass -File workflow\tools\protect_original_data.ps1
```
3. Verify
```powershell
powershell -ExecutionPolicy Bypass -File workflow\tools\verify_permissions.ps1
```

## 4) Fast ACL fallback (if still blocked)
For current main workspace `D:\paper\IJIO_GMM_codex_en`:
```powershell
icacls "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\data\work" /grant:r "WENXIAO\dongw:(OI)(CI)F" /T /C
icacls "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\results\data" /grant:r "WENXIAO\dongw:(OI)(CI)F" /T /C
icacls "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\results\logs" /grant:r "WENXIAO\dongw:(OI)(CI)F" /T /C
```

## 5) Consistency rule (must follow)
For file outputs in main chain, use direct `replace`.

Example:
```stata
save "$DATA_WORK/example.dta", replace
```

For logs:
```stata
log using "`log_file'", text replace
```

## 6) Validation checklist
- No `r(608)` in latest run log
- Main outputs updated in:
  - `$DATA_WORK`
  - `$RES_DATA`
  - `$RES_LOG`
- `results/logs/main_twogroups_full_log_YYYYMMDD.log` and `results/logs/main_twogroups_final_log_YYYYMMDD.log` both produced
