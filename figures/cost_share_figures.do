clear all
cd "D:\鏂囩珷鍙戣〃\娆ｆ槉\input markdown\IJIO\IJIO_GMM\methods\non_hicks"

clear 
use "D:\鏂囩珷鍙戣〃\娆ｆ槉\input markdown\IJIO\junenewg.dta"

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
merge m:1 year using "D:\鏂囩珷鍙戣〃\娆ｆ槉\input markdown\IJIO\Brandt-Rawski investment deflator.dta"
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
gen input_cost = domesticint + importint

gen foreign_input_share = importint/input_cost
*drop if foreign_input_share<0.02
*drop if ratio>0.98
//gen foreign_input_share = input_cost/total_cost

gen domestic_input_share = domesticint/total_cost



**鍔犳潈锛氬叏鍥?foreign input cost share 骞村害瓒嬪娍
preserve
keep if inlist(cic2, 17, 18, 19, 39, 40, 41)
collapse (mean) foreign_input_share [aw=宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓], by(year)

twoway ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "foreign input") position(12) ring(0) cols(1) region(lstyle(none))) ///
       title("Annual Mean Foreign Input Cost Share (Weighted)") ///
       xtitle("year") ytitle("foreign input cost share (Weighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
	       * 鍑哄浘鐗?
    graph export "foreign_input_share_total.png", width(2000) replace
restore

preserve
    * 鍙繚鐣欎袱缁勮涓?
    keep if inlist(cic2, 17, 18, 19, 39, 40, 41)

    * 鐢熸垚涓ゅぇ绫诲垎缁勶細缁?=17/18/19锛涚粍2=39/40/41
    gen byte biggrp = .
    replace biggrp = 1 if inlist(cic2, 17, 18, 19)
    replace biggrp = 2 if inlist(cic2, 39, 40, 41)
    label define BIGGRP 1 "Group 1: 17/18/19" 2 "Group 2: 39/40/41"
    label values biggrp BIGGRP
    * 鍦?骞疵楀ぇ缁?灞傞潰璁＄畻"鍔犳潈鍧囧€?
    collapse (mean) foreign_input_share [aw = 宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓], by(year biggrp)
    twoway ///
      (connected foreign_input_share year if biggrp==1, sort ///
         lcolor(red)   lpattern(solid) ///
         msymbol(O)    mcolor(red)     mfcolor(none) lwidth(medium)) ///
      (connected foreign_input_share year if biggrp==2, sort ///
         lcolor(blue)  lpattern(solid)  ///
         msymbol(O)    mcolor(blue)    mfcolor(none) lwidth(medium)), ///
         legend(order(1 "Group 1: 17/18/19" 2 "Group 2: 39/40/41") ///
                position(6) ring(1) rows(1) region(lstyle(none))) ///
         title("Annual Mean Foreign Input Cost Share (Weighted)") ///
         xtitle("year") ytitle("foreign input cost share (Weighted)") ///
         xlabel(2000(1)2007) ///
         xscale(range(2000 2007)) ///
         graphregion(color(white))
    * 鍑哄浘鐗?
    graph export "foreign_input_share_two_groups.png", width(2000) replace

restore
*============================*
* 鍙傛暟锛氭寜闇€鏀规垚浣犵殑鍙橀噺鍚?
*============================*
local yvar    foreign_input_share
local wvar    宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓

* 鍙繚鐣欏叚涓洰鏍囪涓?
keep if inlist(cic2,17,18,19,39,40,41)

* 鍙栧嚭琛屼笟鍒楄〃
levelsof cic2, local(sectors)

* 鐢ㄤ簬鏈€鍚?graph combine 鐨勫鍣?
local gphlist

foreach s of local sectors {
    preserve
        * 鍙暀璇ヨ涓?
        keep if cic2==`s'

        * 骞村害鍔犳潈鍧囧€硷紙鍙彉鎴愭湰鏉冮噸锛?
        collapse (mean) `yvar' [aw=`wvar'], by(year)

        * 鐢诲浘骞朵繚瀛?gph
        twoway ///
            (connected `yvar' year, lcolor(blue) lpattern(solid) ///
                msymbol(O) mcolor(navy) mfcolor(none) lwidth(medthick)), ///
            title("Sector `s' 鈥?Annual Mean Foreign Input Cost Share (Weighted)") ///
            xtitle("Year") ytitle("Foreign input cost share") ///
            xlabel(2000(1)2007, grid) xscale(range(2000 2007)) ///
            legend(off) graphregion(color(white)) ///
            name(fig_`s', replace)

        * 淇濆瓨鍗曞紶鍥剧墖
        graph export "fig_fis_sector`=string(`s',"%02.0f")'.png", width(1600) replace

        * 淇濆瓨 gph 浠ヤ究鍚堝苟
        graph save fig_`s'.gph, replace
        local gphlist `gphlist' fig_`s'.gph
    restore
}


























