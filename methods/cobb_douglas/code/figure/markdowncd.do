clear all
set more off

capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/cobb_douglas"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"
*鈽呬粎杩欏涓庡師鑴氭湰涓嶅悓璇诲彇鏃剁洿鎺ユ寜琛屼笟杩囨护锛堝叾浣欎唬鐮佷繚鎸佸師鏍凤級鈽?use "$DATA_WORK/firststageCD.dta", clear
merge m:1 cic2 using "$RES_DATA/gmm_point_industry.dta"
keep if _merge==3
drop _merge
gen markdowncd1=b_x/b_m
gen mdcd2=domesticint/importint
gen markdownCD=markdowncd1*mdcd2
keep cic2 firmid year markdownCD
save "$DATA_WORK/mdCD.dta", replace
