clear all
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"

clear 
use "D:\文章发表\欣昊\input markdown\IJIO\junenewg.dta"

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
merge m:1 year using "D:\文章发表\欣昊\input markdown\IJIO\Brandt-Rawski investment deflator.dta"
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
gen input_cost = domesticint + importint

gen foreign_input_share = importint/input_cost
*drop if foreign_input_share<0.02
*drop if ratio>0.98
//gen foreign_input_share = input_cost/total_cost

gen domestic_input_share = domesticint/total_cost



**加权：全国 foreign input cost share 年度趋势
preserve
keep if inlist(cic2, 17, 18, 19, 39, 40, 41)
collapse (mean) foreign_input_share [aw=工业总产值_当年价格千元], by(year)

twoway ///
  (connected foreign_input_share year, lcolor(red) lpattern(solid) msymbol(O) mcolor(red) mfcolor(none) lwidth(medium)), ///
       legend(order(1 "foreign input") position(12) ring(0) cols(1) region(lstyle(none))) ///
       title("Annual Mean Foreign Input Cost Share (Weighted)") ///
       xtitle("year") ytitle("foreign input cost share (Weighted)") ///
       xlabel(2000(1)2007 ) ///
       xscale(range(2000 2007)) ///
       graphregion(color(white))
	       * 出图片
    graph export "foreign_input_share_total.png", width(2000) replace
restore

preserve
    * 只保留两组行业
    keep if inlist(cic2, 17, 18, 19, 39, 40, 41)

    * 生成两大类分组：组1=17/18/19；组2=39/40/41
    gen byte biggrp = .
    replace biggrp = 1 if inlist(cic2, 17, 18, 19)
    replace biggrp = 2 if inlist(cic2, 39, 40, 41)
    label define BIGGRP 1 "Group 1: 17/18/19" 2 "Group 2: 39/40/41"
    label values biggrp BIGGRP
    * 在 年×大组 层面计算"加权均值"
    collapse (mean) foreign_input_share [aw = 工业总产值_当年价格千元], by(year biggrp)
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
    * 出图片
    graph export "foreign_input_share_two_groups.png", width(2000) replace

restore
*============================*
* 参数：按需改成你的变量名
*============================*
local yvar    foreign_input_share
local wvar    工业总产值_当年价格千元

* 只保留六个目标行业
keep if inlist(cic2,17,18,19,39,40,41)

* 取出行业列表
levelsof cic2, local(sectors)

* 用于最后 graph combine 的容器
local gphlist

foreach s of local sectors {
    preserve
        * 只留该行业
        keep if cic2==`s'

        * 年度加权均值（可变成本权重）
        collapse (mean) `yvar' [aw=`wvar'], by(year)

        * 画图并保存 gph
        twoway ///
            (connected `yvar' year, lcolor(blue) lpattern(solid) ///
                msymbol(O) mcolor(navy) mfcolor(none) lwidth(medthick)), ///
            title("Sector `s' — Annual Mean Foreign Input Cost Share (Weighted)") ///
            xtitle("Year") ytitle("Foreign input cost share") ///
            xlabel(2000(1)2007, grid) xscale(range(2000 2007)) ///
            legend(off) graphregion(color(white)) ///
            name(fig_`s', replace)

        * 保存单张图片
        graph export "fig_fis_sector`=string(`s',"%02.0f")'.png", width(1600) replace

        * 保存 gph 以便合并
        graph save fig_`s'.gph, replace
        local gphlist `gphlist' fig_`s'.gph
    restore
}

























