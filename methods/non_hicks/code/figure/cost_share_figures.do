capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_hicks"
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
///鍥藉唴涓棿鍝佽浆鍖栦负1缇庡厓锛屽浗澶栦腑闂村搧鍘熸湰鐨勮浠峰氨鏄?缇庡厓
replace 宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓=宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓*1000/e
gen domes_int = ln(domesticint)
gen for_int = ln(importint)
gen mf = ln(firmtotalq)
replace output = ln(宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓)
drop if 搴斾粯宸ヨ祫钖叕鎬婚鍗冨厓 < 0 
gen labor_payments = 搴斾粯宸ヨ祫钖叕鎬婚鍗冨厓*1000/e

drop if domesticint <= 0 

drop if importint <= 0 

rename 鍥哄畾璧勪骇鍚堣鍗冨厓 K
merge m:1 year using "$DATA_RAW/Brandt-Rawski investment deflator.dta"
drop if year < 2000
replace BR_deflator = 116.7 if year == 2007
drop _merge
*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
* 2) Compute firm鈥恖evel investment I_t = K_t 鈥?K_{t-1}

*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
bysort firmid (year): gen double I = K - K[_n-1]

by firmid: replace I = K if _n == 1
* inv0:

bysort firmid (year): gen double inv0 = I

replace inv0 = 0 if missing(inv0)

* inv1 鈥?inv19:

forvalues v = 1/19 {

    bysort firmid (year): gen double inv`v' = I[_n-`v'] * (BR_deflator / BR_deflator[_n-`v'])  if _n > `v'

     

    replace inv`v' = 0 if missing(inv`v')

}

 

*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
* 4) Sum them all into K_current

*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
gen double K_current = inv0

forvalues v = 1/19 {

    replace K_current = K_current + inv`v'

}

 

*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
drop inv0 - inv19
sum K_current, detail

replace K_current = K_current*1000/e

replace K=K_current

drop K_current

**0.10锛氫负涓浗璁惧畾鐨勮祫鏈洖鎶ョ巼; delta = 0.05锛氱粺涓€璁惧畾鐨勬姌鏃х巼
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
***娌℃湁鍔犳潈
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
***鍔犳潈骞冲潎
* 鎸夊勾浠借绠楀姞鏉冨潎鍊?collapse (mean) labor_share foreign_input_share domestic_input_share [aw=宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓], by(year)

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
collapse (mean) labor_share foreign_input_share domestic_input_share [aw=宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓], by(cic2 year)

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

****鍙湁鍥藉涓棿鍝佺殑鍥?**涓嶅姞鏉冿細鍏ㄥ浗 foreign input cost share 骞村害瓒嬪娍
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

**鍔犳潈锛氬叏鍥?foreign input cost share 骞村害瓒嬪娍
preserve
collapse (mean) foreign_input_share [aw=宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓], by(year)

twoway ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "foreign input") position(12) ring(0) cols(1) region(lstyle(none))) ///
       title("Annual Mean Foreign Input Cost Share (Weighted)") ///
       xtitle("year") ytitle("foreign input cost share (Weighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
restore

**鍒嗚涓氾紙cic2锛夊姞鏉?annual foreign input cost share 寰幆鍑哄浘
preserve
collapse (mean) foreign_input_share [aw=宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓], by(cic2 year)

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


