# Stage3 Static Checklist (No Stata Run)

- Date: 2026-02-08
- Scope: `code/master`, `code/estimate`, `code/figure`
- Result: `active_path_issues = 0` for active (non-comment) commands.

## Fixed In This Round
- Rewired raw-data merges to `$DATA_RAW`:
  - `Brandt-Rawski investment deflator.dta`
  - `firm_year_IVs_Ztariff_ZHHI.dta`
- Repaired header/readability block in `code/estimate/1109_01.do`.

## File-By-File Risk Points

### A. ROOT fallback absolute path
These are fallback lines. They work in current workspace, but can fail after relocating the project unless `global ROOT` is set first.
- `1017/1022_non_hicks/code/master/Master_1110.do:10`
- `1017/1022_non_hicks/code/master/Master_Non_hicks.do:14`
- `1017/1022_non_hicks/code/master/run_G1_1110.do:5`
- `1017/1022_non_hicks/code/master/run_G2_1110.do:5`
- `1017/1022_non_hicks/code/master/run_group_G1.do:5`
- `1017/1022_non_hicks/code/master/run_group_G2.do:5`
- `1017/1022_non_hicks/code/estimate/1109_01.do:18`
- `1017/1022_non_hicks/code/estimate/1109_con_out_method.do:20`
- `1017/1022_non_hicks/code/estimate/bootstrap0901_group.do:20`
- `1017/1022_non_hicks/code/estimate/bootstrap0901_group_1101.do:21`
- `1017/1022_non_hicks/code/estimate/bootstrap1201_groupdo.do:20`
- `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do:16`
- `1017/1022_non_hicks/code/estimate/firststagenon-hicks.do:4`
- `1017/1022_non_hicks/code/figure/aft_figure_1103xinhao.do:9`
- `1017/1022_non_hicks/code/figure/aft_figure_1103xinhao.do:83`
- `1017/1022_non_hicks/code/figure/aft_figure_1103xinhao.do:165`
- `1017/1022_non_hicks/code/figure/cost_share_figures.do:4`
- `1017/1022_non_hicks/code/figure/decom_by_biggroup.do:10`
- `1017/1022_non_hicks/code/figure/Markdown_figure.do:10`
- `1017/1022_non_hicks/code/figure/markdownnon-Hicks.do:9`
- `1017/1022_non_hicks/code/figure/tfp_figure_non_hicks_1104.do:4`

### B. Commented external data path
These lines are inside comment blocks now (not executed). If uncommented, replace with project-local paths first.
- `1017/1022_non_hicks/code/estimate/1109_01.do:45`
- `1017/1022_non_hicks/code/estimate/1109_con_out_method.do:46`
- `1017/1022_non_hicks/code/estimate/bootstrap0901_group_1101.do:47`

## Note
- `code/prep` is outside this main-flow checklist and still contains historical absolute paths.
