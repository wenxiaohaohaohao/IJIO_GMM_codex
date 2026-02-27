*******************************************************
* bootstrap0901_group.do
* Usage:
*   do "$CODE/estimate/bootstrap0901_group.do"    // pooled {17,18,19}, IV spec of 18
*   do "$CODE/estimate/bootstrap0901_group.do"    // pooled {39,40,41}, IV spec of 40
* Outputs (per group):
*   - gmm_point_group_<GROUP>.dta   (point + bootstrap SEs + J + N)
*   - gmm_boot_group_<GROUP>.dta    (bootstrap draws)

* [瀹氫箟闃舵]  鍏堝畾涔夛細Mata鍑芥暟 + Stata鐨刾rogram  gmm2step_once
* [鎵ц闃舵]  for 姣忔bootstrap澶嶅埗锛?*              -> 璋?gmm2step_once (Stata)
*              -> 璋?mata:refresh_globals() (Mata)
*              -> 璋?mata:run_two_step()    (Mata, 鐪熸浼樺寲)
*              <- 缁撴灉鍥炲埌 Stata, 瀛樺叆 r()

*******************************************************

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
* 姣忎釜缁勫紑澶撮兘閲嶇疆璧风偣锛屽苟鎶?have_b0 浼犲叆 Mata

use "$DATA_RAW/junenewg_0902", clear
/*
merge 1:m firmid year using "$DATA_RAW/nonneutraltartiff.dta"
keep if _merge==3
drop _merge
*/


* -------- Group filter (by GROUPNAME) -------- *


duplicates drop firmid year, force

* year numeric
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,")
xtset firmid year

// ===== Your pipeline (unchanged aside from tariff inclusion) =====
gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

drop if domesticint <= 0
drop if 钀ヤ笟鏀跺叆鍚堣鍗冨厓 < 40

gen double R = 宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓 * 1000 / e

rename 鍥哄畾璧勪骇鍚堣鍗冨厓 K
drop if K < 30
rename 鍏ㄩ儴浠庝笟浜哄憳骞村钩鍧囦汉鏁颁汉 L
replace L = 骞存湯浠庝笟浜哄憳鍚堣浜?if year==2003
drop if L < 8

rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

gen double WL = 搴斾粯宸ヨ祫钖叕鎬婚鍗冨厓 * 1000 / e

capture confirm variable firmtotalq
if !_rc rename firmtotalq X

* Merge investment deflator and reconstruct capital
merge m:1 year using "$DATA_RAW/Brandt-Rawski investment deflator.dta", nogen
replace BR_deflator = 116.7 if year == 2007
drop if year < 2000

bysort firmid (year): gen double I = K - K[_n-1]
bysort firmid (year): replace I = K if _n == 1

bysort firmid (year): gen double inv0 = I
replace inv0 = 0 if missing(inv0)
forvalues v = 1/19 {
    bysort firmid (year): gen double inv`v' = I[_n-`v'] * (BR_deflator / BR_deflator[_n-`v']) if _n > `v'
    replace inv`v' = 0 if missing(inv`v')
}
gen double K_current = inv0
forvalues v = 1/19 {
    replace K_current = K_current + inv`v'
}
drop inv0-inv19
replace K = K_current

rename 宸ヤ笟涓棿鎶曞叆鍚堣鍗冨厓 MI
rename 绠＄悊璐圭敤鍗冨厓 Mana

gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0
capture ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen double lratiofs = lnR - lnM

gen ratio = importint/(domesticint+importint)
*drop if ratio<0.02    *************************************change
*drop if ratio>0.98

gen inputp = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF = importint/einputp

replace 寮€涓氭垚绔嬫椂闂村勾 = . if 寮€涓氭垚绔嬫椂闂村勾==0
gen age   = year - 寮€涓氭垚绔嬫椂闂村勾 + 1
gen lnage = ln(age)
gen lnmana = ln(Mana)

gen  l  = ln(L)
gen  lsq = l*l 
gen double k  = ln(K)
gen  ksq = k*k  
gen double q  = ln(Q)
gen m = ln(delfateddomestic)        
gen double x  = ln(X)
gen double r  = ln(R)
gen DWL=WL/L
gen wl=ln(DWL)
xtset firmid year

capture confirm variable pft
if !_rc rename pft pi
capture confirm variable foreignprice
if !_rc rename foreignprice WX
capture confirm variable WX
if !_rc gen double wx = ln(WX)

* First stage  (ADD tariff as you asked)(鍏堟妸鍏崇◣鍒犻櫎鎺夛紝涔嬪悗鍐嶈)
reg lratiofs k l wl x age lnmana i.firmtype i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2

* phi cubic (unchanged)
reg r c.(l k m x pi wx wl )##c.(l k m x pi wx wl )##c.(l k m x pi wx wl) ///
    age i.firmtype i.city i.year
// 鍥炲綊锛堜綘鐨勭涓€闃舵锛夊悗锛氶娴嬪悗鍙鏈夋晥鏍锋湰璧嬪€硷紙閬垮厤 predict 鍥犵己椤逛骇鐢熺殑 173 涓己澶辨贩鍏ワ級
predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "$DATA_WORK/firststageCD.dta", replace


