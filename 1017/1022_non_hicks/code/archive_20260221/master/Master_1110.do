/* main_twogroups.do
   Outputs:
     - nonhicks_points_by_group.dta  (points + bootstrap SEs + J + N)
     - nonhicks_ses_by_group.dta     (SEs only, convenience)
*/

clear all
set more off
capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"


* 1) Run GMM exactly twice (each pooled group)

do "$CODE/master/run_G1_1110.do"
do "$CODE/master/run_G2_1110.do"

* 2) Combine POINTS (already includes se_* from bootstrap do)
use "$DATA_WORK/gmm_point_group_G1_17_19.dta", clear
append using "$DATA_WORK/gmm_point_group_G2_39_41.dta"

order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq b_m se_m b_es se_es b_essq se_essq b_lnage b_firmcat_2 b_firmcat_3  J_unit J_opt J_df J_p N
compress
save "$RES_DATA/nonhicks_points_by_group.dta", replace

* 3) Also emit SE-only table (optional)
preserve
    keep group se_const se_l se_k se_lsq se_ksq se_m se_es se_essq
    compress
    save "$RES_DATA/nonhicks_ses_by_group.dta", replace
restore

display as res "Wrote:"
display as res "  nonhicks_points_by_group.dta"
display as res "  nonhicks_ses_by_group.dta"

* ============ 1) 读入两组结果并合并成一张 group 级表 ============
clear
use "$DATA_WORK/gmm_point_group_G1_17_19.dta", clear
append using "$DATA_WORK/gmm_point_group_G2_39_41.dta"

* 保留原来的 group 名到 group_pool，新增一个按你要求显示的 GI 标签
rename group group_pool
gen str10 group = cond(group_pool=="G1_17_19","GI_17_19","GI_39_41")

* ============ 2) 做一张 "group→cic2" 的映射表 ============
preserve
clear
input str10 group_pool byte cic2
"G1_17_19" 17
"G1_17_19" 18
"G1_17_19" 19
"G2_39_41" 39
"G2_39_41" 40
"G2_39_41" 41
end
tempfile map
save "`map'", replace
restore

* ============ 3) 1:m 按 group_pool 复制到每个 cic2 ============
merge 1:m group_pool using "`map'", keep(match) nogen

* 清理并排版
drop group_pool J_unit J_opt J_df J_p N
order cic2 group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq b_m se_m b_es se_es b_essq se_essq b_lnage b_firmcat_2 b_firmcat_3 
	  
label var group "GI group label (mapped by cic2)"

* 保存分行业表（每个 cic2 一行，数值等于对应组的结果）
compress
save "$RES_DATA/gmm_point_industry.dta", replace
