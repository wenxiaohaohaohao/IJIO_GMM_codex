capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


clear all
cd "$ROOT"

clear 
use "$DATA_RAW/junenewg.dta"

duplicates drop firmid year, force

**********************AR(1) Aft*************************************************
gen e = 0
replace e=8.2784 if year==2000
replace e=8.2770 if year==2001
replace e=8.2770 if year==2002
replace e=8.2770 if year==2003
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.604 if year==2007
///国内中间品转化为1美元，国外中间品原本的计价就是1美元
replace 工业总产值_当年价格千元=工业总产值_当年价格千元*1000/e
gen domes_int = ln(domesticint)
gen for_int = ln(importint)
gen mf = ln(firmtotalq)
replace output = ln(工业总产值_当年价格千元)
drop if 应付工资薪酬总额千元 < 0 
gen labor_payments = 应付工资薪酬总额千元*1000/e

drop if domesticint <= 0 

drop if importint <= 0 

rename 固定资产合计千元 K
merge m:1 year using "$DATA_RAW/Brandt-Rawski investment deflator.dta"
drop if year < 2000
replace BR_deflator = 116.7 if year == 2007
drop _merge
*———————————————————————————————

* 2) Compute firm‐level investment I_t = K_t – K_{t-1}

*———————————————————————————————

bysort firmid (year): gen double I = K - K[_n-1]

by firmid: replace I = K if _n == 1
* inv0:

bysort firmid (year): gen double inv0 = I

replace inv0 = 0 if missing(inv0)

* inv1 … inv19:

forvalues v = 1/19 {

    bysort firmid (year): gen double inv`v' = I[_n-`v'] * (BR_deflator / BR_deflator[_n-`v'])  if _n > `v'

     

    replace inv`v' = 0 if missing(inv`v')

}

 

*———————————————————————————————

* 4) Sum them all into K_current

*———————————————————————————————

gen double K_current = inv0

forvalues v = 1/19 {

    replace K_current = K_current + inv`v'

}

 

*———————————————————————————————

drop inv0 - inv19
sum K_current, detail

replace K_current = K_current*1000/e

replace K=K_current

drop K_current

**0.10：为中国设定的资本回报率; delta = 0.05：统一设定的折旧率
gen cost_of_capital = .
replace cost_of_capital = 0.10 + 0.05 
gen capital_payment = cost_of_capital*K

gen total_cost  = labor_payments + domesticint + importint + capital_payment

gen labor_share = labor_payments/total_cost

gen foreign_input_share = importint/total_cost

gen domestic_input_share = domesticint/total_cost

*bysort firmid: egen n_years = count(year)
*bysort firmid: gen first = _n==1
*tab n_years if first

preserve
***没有加权
collapse (mean) labor_share foreign_input_share domestic_input_share, by(year)
twoway ///
  (connected labor_share year, lcolor(blue) lpattern(dash) msymbol(O) mcolor(blue) mfcolor(none) lwidth(medium)) ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)) ///
  (connected domestic_input_share year, lcolor(black) lpattern(solid) msymbol(O) mcolor(black) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "labor" 2 "foreign input" 3 "domestic input") ///
              position(12) ring(0) cols(3) region(lstyle(none))) ///
       title("Annual Mean Cost Shares") ///
       xtitle("year") ytitle("cost share (Unweighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
restore

preserve
***加权平均
* 按年份计算加权均值
collapse (mean) labor_share foreign_input_share domestic_input_share [aw=工业总产值_当年价格千元], by(year)

twoway ///
  (connected labor_share year, lcolor(blue) lpattern(dash) msymbol(O) mcolor(blue) mfcolor(none) lwidth(medium)) ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)) ///
  (connected domestic_input_share year, lcolor(black) lpattern(solid) msymbol(O) mcolor(black) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "labor" 2 "foreign input" 3 "domestic input") ///
              position(12) ring(0) cols(3) region(lstyle(none))) ///
       title("Annual Mean Cost Shares") ///
       xtitle("year") ytitle("cost share (Weighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
restore

preserve
collapse (mean) labor_share foreign_input_share domestic_input_share [aw=工业总产值_当年价格千元], by(cic2 year)

levelsof cic2, local(indlist)
foreach ind of local indlist {
    twoway ///
      (connected labor_share year if cic2 == `ind', lcolor(blue) lpattern(dash) msymbol(O) mcolor(blue) mfcolor(none) lwidth(medium)) ///
      (connected foreign_input_share year if cic2 == `ind', lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)) ///
      (connected domestic_input_share year if cic2 == `ind', lcolor(black) lpattern(solid) msymbol(O) mcolor(black) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "labor" 2 "foreign input" 3 "domestic input") ///
              position(12) ring(0) cols(3) region(lstyle(none))) ///
      title("Industry `ind': Annual Mean Cost Shares") ///
       xtitle("year") ytitle("cost share (Weighted)") ///
      xlabel(2000(1)2007, grid) ///
      xscale(range(2000 2007)) ///
      ylabel(, grid) ///
      graphregion(color(white))
    graph export cost_share_cic2_`ind'_weighted.png, replace width(1200)
}
restore

****只有国外中间品的图
**不加权：全国 foreign input cost share 年度趋势
preserve
collapse (mean) foreign_input_share, by(year)

twoway ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "foreign input") position(12) ring(0) cols(1) region(lstyle(none))) ///
       title("Annual Mean Foreign Input Cost Share (Unweighted)") ///
       xtitle("year") ytitle("foreign input cost share (Unweighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
restore

**加权：全国 foreign input cost share 年度趋势
preserve
collapse (mean) foreign_input_share [aw=工业总产值_当年价格千元], by(year)

twoway ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "foreign input") position(12) ring(0) cols(1) region(lstyle(none))) ///
       title("Annual Mean Foreign Input Cost Share (Weighted)") ///
       xtitle("year") ytitle("foreign input cost share (Weighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
restore

**分行业（cic2）加权 annual foreign input cost share 循环出图
preserve
collapse (mean) foreign_input_share [aw=工业总产值_当年价格千元], by(cic2 year)

levelsof cic2, local(indlist)
foreach ind of local indlist {
    twoway ///
      (connected foreign_input_share year if cic2 == `ind', lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "foreign input") position(12) ring(0) cols(1) region(lstyle(none))) ///
       title("Industry `ind': Annual Mean Foreign Input Cost Share (Weighted)") ///
       xtitle("year") ytitle("foreign input cost share (Weighted)") ///
       xlabel(2000(1)2007, grid) ///
       xscale(range(2000 2007)) ///
       ylabel(, grid) ///
       graphregion(color(white))
    graph export cost_share_cic2_`ind'_foreign_weighted.png, replace width(1200)
}
restore

