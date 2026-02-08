capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


//使用原始数据,最大m:m匹配到96层面
clear
use "$DATA_RAW/中国海关企业数据库（firm-year-hs6）.dta"
rename hs6 hs2002
keep if year<=2007
merge m:m hs2002 using "$DATA_RAW/hs02to96.dta"
//复原2001年之前的
replace hs6=hs2002 if year<2002
drop hs2002
rename hs6 hs2007
drop _merge
merge m:m hs2007 using "$DATA_RAW/hs07to96.dta"
//复原2001年之前的
replace hs6=hs2007 if year<2007
drop hs2007
drop _merge
save "$DATA_WORK/中国海关企业数据库（firm-year-hs6）v2.dta", replace
