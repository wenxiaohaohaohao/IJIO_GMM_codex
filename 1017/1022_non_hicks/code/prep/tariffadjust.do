capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


//使用原始数据,最大m:m匹配到07层面
cd"$ROOT"
clear
use "$DATA_RAW/tariffnew.dta"
keep if year>=2002
keep if year<2007
rename hs6 hs2002
merge m:m hs2002 using "$DATA_RAW/hs02to96.dta"
drop _merge
drop hs2002

save "$DATA_WORK/part2.dta", replace

clear
use "$DATA_RAW/tariffnew.dta"
keep if year<=2001
save "$DATA_WORK/part1.dta", replace

clear
use "$DATA_RAW/tariffnew.dta"
keep if year==2007
rename hs6 hs2007
merge m:m hs2007 using "$DATA_RAW/hs07to96.dta"
drop _merge
drop hs2007

save "$DATA_WORK/part3.dta", replace

clear
use "$DATA_WORK/part3.dta"
append using "$DATA_WORK/part2.dta"
append using "$DATA_WORK/part1.dta"

save "$DATA_RAW/finalimporttariff.dta", replace
erase "$DATA_WORK/part1.dta"
erase "$DATA_WORK/part2.dta"
erase "$DATA_WORK/part3.dta"
