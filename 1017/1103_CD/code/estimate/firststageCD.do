*******************************************************
* bootstrap0901_group.do
* Usage:
*   do "$CODE/estimate/bootstrap0901_group.do"    // pooled {17,18,19}, IV spec of 18
*   do "$CODE/estimate/bootstrap0901_group.do"    // pooled {39,40,41}, IV spec of 40
* Outputs (per group):
*   - gmm_point_group_<GROUP>.dta   (point + bootstrap SEs + J + N)
*   - gmm_boot_group_<GROUP>.dta    (bootstrap draws)

* [定义阶段]  先定义：Mata函数 + Stata的program  gmm2step_once
* [执行阶段]  for 每次bootstrap复制：
*              -> 调 gmm2step_once (Stata)
*              -> 调 mata:refresh_globals() (Mata)
*              -> 调 mata:run_two_step()    (Mata, 真正优化)
*              <- 结果回到 Stata, 存入 r()

*******************************************************

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
* 每个组开头都重置起点，并把 have_b0 传入 Mata

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
drop if 营业收入合计千元 < 40

gen double R = 工业总产值_当年价格千元 * 1000 / e

rename 固定资产合计千元 K
drop if K < 30
rename 全部从业人员年平均人数人 L
replace L = 年末从业人员合计人 if year==2003
drop if L < 8

rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

gen double WL = 应付工资薪酬总额千元 * 1000 / e

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

rename 工业中间投入合计千元 MI
rename 管理费用千元 Mana

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

replace 开业成立时间年 = . if 开业成立时间年==0
gen age   = year - 开业成立时间年 + 1
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

* First stage  (ADD tariff as you asked)(先把关税删除掉，之后再说)
reg lratiofs k l wl x age lnmana i.firmtype i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2

* phi cubic (unchanged)
reg r c.(l k m x pi wx wl )##c.(l k m x pi wx wl )##c.(l k m x pi wx wl) ///
    age i.firmtype i.city i.year
// 回归（你的第一阶段）后：预测后只对有效样本赋值（避免 predict 因缺项产生的 173 个缺失混入）
predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "$DATA_WORK/firststageCD.dta", replace

