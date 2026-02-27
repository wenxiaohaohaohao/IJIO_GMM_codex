/* main_twogroups.do
   Outputs:
     - nonhicks_points_by_group.dta  (points + bootstrap SEs + J + N)
     - nonhicks_ses_by_group.dta     (SEs only, convenience)
*/

clear all
set more off
capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_markdown_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"

* 1) Run GMM exactly twice (each pooled group)

do "$CODE/master/run_group_G1.do"
do "$CODE/master/run_group_G2.do"

* 2) Combine POINTS (already includes se_* from bootstrap do)
use "$DATA_WORK/gmm_point_group_G1_17_19.dta", clear
append using "$DATA_WORK/gmm_point_group_G2_39_41.dta"

order group ///
  b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq ///
  b_m se_m b_S2q se_S2q J_unit J_opt N
compress
save "$RES_DATA/nonhicks_points_by_group.dta", replace

* 3) Also emit SE-only table (optional)
preserve
    keep group se_const se_l se_k se_lsq se_ksq se_m se_S2q 
    compress
    save "$RES_DATA/nonhicks_ses_by_group.dta", replace
restore

display as res "Wrote:"
display as res "  nonhicks_points_by_group.dta"
display as res "  nonhicks_ses_by_group.dta"


* ============ 1) 璇诲叆涓ょ粍缁撴灉骞跺悎骞舵垚涓€寮?group 绾ц〃 ============
clear
use "$DATA_WORK/gmm_point_group_G1_17_19.dta", clear
append using "$DATA_WORK/gmm_point_group_G2_39_41.dta"

* 淇濈暀鍘熸潵鐨?group 鍚嶅埌 group_pool锛屾柊澧炰竴涓寜浣犺姹傛樉绀虹殑 GI 鏍囩
rename group group_pool
gen str10 group = cond(group_pool=="G1_17_19","GI_17_19","GI_39_41")

* ============ 2) 鍋氫竴寮?"group鈫抍ic2" 鐨勬槧灏勮〃 ============
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

* ============ 3) 1:m 鎸?group_pool 澶嶅埗鍒版瘡涓?cic2 ============
merge 1:m group_pool using "`map'", keep(match) nogen

* 娓呯悊骞舵帓鐗?drop group_pool J_unit J_opt J_df J_p N
order cic2 group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq ///
      b_m se_m b_S2q se_S2q 
label var group "GI group label (mapped by cic2)"

* 淇濆瓨鍒嗚涓氳〃锛堟瘡涓?cic2 涓€琛岋紝鏁板€肩瓑浜庡搴旂粍鐨勭粨鏋滐級
compress
save "$RES_DATA/gmm_point_industry.dta", replace

