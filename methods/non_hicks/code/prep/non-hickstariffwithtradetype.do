clear all
set more off
capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"


use "$DATA_RAW/all_years_2000_2007.dta",clear
keep if expimp==1
drop if missing(value) | missing(year) | missing(firmid) | missing(hs6)
collapse (sum) value, by(firmid year hs6 tradetype)
keep if inlist(tradetype, 1, 2)
*==============================================================*
* 浜屻€佹瀯閫犲熀鏈熺粨鏋?伪_ij  鈥斺€?瀹屽叏鎸夌収 Yu 鐨勫仛娉?              *
*   鎬濊矾锛?                                                    *
*   1) 鍙敤鏅€氳锤鏄?(tradetype==1) 鐨勮繘鍙ｉ璁＄畻鍩烘湡缁撴瀯       *
*   2) 鍩烘湡 = 浼佷笟"棣栨鍑虹幇鐨勫勾浠?锛堜紒涓氬紓璐ㄦ€т綋鐜板湪杩欎竴骞达級  *
*   3) 瀵规瘡涓紒涓氾紝鎶婂熀鏈熸櫘閫氳繘鍙ｆ寜 HS6 鍋?share              *
*   4) 寰楀埌 伪_ij = value_ij0 / 危_j value_ij0                  *
*==============================================================*
preserve
keep if tradetype == 1
bysort firmid: egen baseyear = min(year)
keep if year==baseyear
bysort firmid: egen tot0 = total(value)
* 鍩烘湡鏉冮噸 伪_ij锛氭煇HS6鍦ㄥ熀鏈熺殑鏅€氳繘鍙ｉ / 浼佷笟鍩烘湡鏅€氳繘鍙ｉ
gen share0 = value/tot0 if tot0>0
keep firmid hs6 share0
tempfile SHARE0
save `SHARE0', replace
restore

preserve
use "$DATA_RAW/finalimporttariff.dta",clear
drop if missing(year) | missing(hs6) | missing(tariff)

bysort year hs6: egen tariff_u = mean(tariff)
bysort year hs6: keep if _n==1
drop tariff
rename tariff_u tariff
tempfile finalimporttariff
save `finalimporttariff', replace
restore

*------ 鍚堝苟鍏崇◣ + 鍚堝苟鍩烘湡鏉冮噸 ------
merge m:1 year hs6 using `finalimporttariff', keep(match) nogen
merge m:1 firmid hs6 using `SHARE0', nogen
drop if tariff==.
replace share0 = 0 if missing(share0)
* 鏋勯€?鏈夋晥鍏崇◣"锛?*   - 鏅€氳锤鏄擄細鐢ㄥ疄闄呭叧绋?tariff
*   - 鍔犲伐璐告槗锛氳涓哄厤绋庯紝璁句负 0
gen tariff_eff = tariff
replace tariff_eff = 0 if tradetype == 2
replace tariff_eff = 0 if missing(tariff_eff)

*==============================================================*
* 浜斻€佽绠椾紒涓氬眰闈㈢殑 input tariff 鎸囨暟 位_it                   *
*   位_it = 危_j 伪_ij * T_jt                                     *
*   鍏朵腑 伪_ij 涓嶉殢鏃堕棿鍙樺寲锛孴_jt 闅忓勾浠藉彉鍖?鈬?位_it 鏄椂闂村彉鐨? *
*==============================================================*

gen z = share0 * tariff_eff

bysort firmid year: egen lambda_input = total(z)

* 濡傛灉浣犲笇鏈涙妸鍗曚綅浠?鐧惧垎鐐?鎹㈢畻鎴愬皬鏁帮紝鍙互闄や互 100锛?gen lambda_input_dec = lambda_input/100

* 淇濈暀浼佷笟鈥撳勾浠藉眰闈㈢殑鎸囨暟锛堥伩鍏嶉噸澶嶏級
keep firmid year lambda_input lambda_input_dec
duplicates drop

* 瀛樻垚涓€涓共鍑€鐨勬暟鎹枃浠讹紝鍚庨潰鍙互鐩存帴 merge 鐢?save "$DATA_WORK/OLStariff_yu_style.dta", replace

*==============================================================*
* 锛堝彲閫夛級鍏€侀『鎵嬬敓鎴愪袱涓姞宸ヨ锤鏄撳彉閲忥細dummy & share         *
*   1) processing_dummy_it锛氬綋骞存槸鍚︽湁鍔犲伐杩涘彛                  *
*   2) processing_share_it锛氬綋骞村姞宸ヨ繘鍙ｉ / 鎬昏繘鍙ｉ           *
*   杩欎袱涓彉閲忓湪鍥炲綊閲岄€氬父涓?位_it 浜や簰浣跨敤                      *
*==============================================================*

use "$DATA_RAW/all_years_2000_2007.dta", clear
keep if expimp == 1
drop if missing(firmid) | missing(year) | missing(hs6) | missing(value)
collapse (sum) value, by(firmid year hs6 tradetype)
keep if inlist(tradetype,1,2)

* 鎬昏繘鍙ｉ & 鍔犲伐杩涘彛棰?bysort firmid year: egen import_total = total(value)
bysort firmid year: egen import_proc  = total(value) if tradetype==2

* 鑱氬悎鍒?firm-year
bysort firmid year: keep if _n==1
replace import_proc = 0 if missing(import_proc)

gen processing_dummy = (import_proc > 0)
gen processing_share = import_proc / import_total if import_total>0

keep firmid year processing_dummy processing_share
save "$DATA_WORK/processing_vars_yu_style.dta", replace


