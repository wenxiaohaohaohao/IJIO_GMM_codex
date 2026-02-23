clear all
set more off

capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1103_CD"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"
*★仅这处与原脚本不同读取时直接按行业过滤（其余代码保持原样）★
use "$DATA_WORK/firststageCD.dta", clear
merge m:1 cic2 using "$RES_DATA/gmm_point_industry.dta"
keep if _merge==3
drop _merge
gen markdowncd1=b_x/b_m
gen mdcd2=domesticint/importint
gen markdownCD=markdowncd1*mdcd2
keep cic2 firmid year markdownCD
save "$DATA_WORK/mdCD.dta", replace