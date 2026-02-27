capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


//浣跨敤鍘熷鏁版嵁,鏈€澶:m鍖归厤鍒?6灞傞潰
clear
use "$DATA_RAW/涓浗娴峰叧浼佷笟鏁版嵁搴擄紙firm-year-hs6锛?dta"
rename hs6 hs2002
keep if year<=2007
merge m:m hs2002 using "$DATA_RAW/hs02to96.dta"
//澶嶅師2001骞翠箣鍓嶇殑
replace hs6=hs2002 if year<2002
drop hs2002
rename hs6 hs2007
drop _merge
merge m:m hs2007 using "$DATA_RAW/hs07to96.dta"
//澶嶅師2001骞翠箣鍓嶇殑
replace hs6=hs2007 if year<2007
drop hs2007
drop _merge
save "$DATA_WORK/涓浗娴峰叧浼佷笟鏁版嵁搴擄紙firm-year-hs6锛塿2.dta", replace

