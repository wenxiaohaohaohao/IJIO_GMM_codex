clear all
set more off

cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表"
use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\markdownTaylor.dta", clear
merge m:1 cic2 firmid year using "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\mdnon-Hicks.dta"
keep if _merge==3
drop _merge
* ============================
* Plot yearly medians by sector (both series use triangle markers)
* Taylor = blue solid line with triangle markers
* Non-Hicks = red  solid line with triangle markers
* Sectors: 17,18,19,39,40,41
* Two panels per combined figure: (17,18), (19,39), (40,41)
* ============================

set more off
set scheme s1color

* --- specify sectors and labels ---
local sectors 17 18 19 39 40 41
local label17  "Textile"
local label18  "Textile and Products"
local label19  "Leather and Products"
local label39  "Electrical Machinery"
local label40  "Communication and Computer"
local label41  "Measuring Instruments"


*-------------------------------------------
* 1) 仅保留六个行业
*-------------------------------------------
keep if inlist(cic2, 17, 18, 19, 39, 40, 41)

* 临时文件
tempfile t_median t_mean

*-------------------------------------------
* 2) 逐年"pooled"中位数
*-------------------------------------------
preserve
    keep year markdownnonHicks
    drop if missing(year) | missing(markdownnonHicks)
    collapse (median) med_nonhicks = markdownnonHicks, by(year)
    save "`t_median'", replace
restore

*-------------------------------------------
* 3) 逐年"pooled"加权均值（权重 = R）
*    说明：使用 aweights，相当于 sum(R*y)/sum(R)
*-------------------------------------------
preserve
    keep year markdownnonHicks R
    drop if missing(year) | missing(markdownnonHicks) | missing(R)
    * 如需剔除非正权重，可加： keep if R>0
    collapse (mean) mean_nonhicks = markdownnonHicks [aw=R], by(year)
    save "`t_mean'", replace
restore

*-------------------------------------------
* 4) 合并两条序列到同一面板并作图
*-------------------------------------------
use "`t_median'", clear
merge 1:1 year using "`t_mean'", nogen

* 去掉两条都缺失的年份（通常用不到，但稳妥）
drop if missing(med_nonhicks) & missing(mean_nonhicks)

* 作图
twoway ///
  (connected mean_nonhicks year, sort ///
      lcolor(blue) lpattern(solid) lwidth(medium) ///
     msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
  (connected med_nonhicks year, sort ///
     lcolor(red) lpattern(dash)  lwidth(medium) ///
     msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)), ///
  ytitle("Markdown") ///
  xtitle("Year") ///
  title("Markdown over Time") ///
  legend(order(1 "Non-Hicks (R-weighted mean)" 2 "Non-Hicks (median)") ///
         position(6) ring(1) cols(2) region(lstyle(none))) ///
  xlabel(, angle(0) grid) ///
  ylabel(, grid) ///
  graphregion(color(white)) ///
  plotregion(fcolor(white))

graph export "Dynamic_markdown.png", replace width(1600)



****************************************************************************
preserve

* keep only relevant sectors (optional)
keep if inlist(cic2, 17, 18, 19, 39, 40, 41)

* compute medians by cic2 and year (one obs per cic2-year)
bysort cic2 year: egen med_taylor = median(markdownTaylor)
bysort cic2 year: egen med_nonhicks = median(markdownnonHicks)
bysort cic2 year: keep if _n==1

* drop years where both medians missing
drop if missing(med_taylor) & missing(med_nonhicks)

* Create an individual graph for each sector (yearly medians)
foreach s of local sectors {
    local lbl ""
    if "`s'"=="17" local lbl "`label17'"
    if "`s'"=="18" local lbl "`label18'"
    if "`s'"=="19" local lbl "`label19'"
    if "`s'"=="39" local lbl "`label39'"
    if "`s'"=="40" local lbl "`label40'"
    if "`s'"=="41" local lbl "`label41'"

    twoway ///
        (connected med_taylor year if cic2==`s', sort ///
            lcolor(blue) lpattern(solid) lwidth(medium) ///
            msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
        (connected med_nonhicks year if cic2==`s', sort ///
            lcolor(red)  lpattern(dash)  lwidth(medium) ///
            msymbol(O) mcolor(red)  mfcolor(none) msize(medlarge)), ///
        ytitle("Markdown") ///
        xtitle("Year") ///
        title("CIC2 `s': `lbl'") ///
        legend(order(1 "Taylor (median)" 2 "Non-Hicks (median)") ///
               position(6) ring(1) cols(2) region(lstyle(none))) ///
        xlabel(, angle(0) grid) ///
        ylabel(, grid) ///
        graphregion(color(white)) ///
        plotregion(fcolor(white))

    * 单独导出每个行业的图形
    graph export "sector_`s'_markdown_median.png", replace width(1200)
}


restore
