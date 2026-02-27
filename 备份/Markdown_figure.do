*******************************************************
* Counterfactual cost-share plots + decomposition table
* Two big groups instead of per-cic2 sectors
* Three curves coincide at base year (2000 or group first year)
* Update: Constant-Technology also fixes mdcd3 at base year (b0)
*******************************************************
clear all
set more off

* --------- FILE PATHS ----------
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"
local d1 "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks\firststage-nonhicks.dta"
local d2 "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks\gmm_point_industry.dta"

* --------- LOAD base ----------
use "`d1'", clear
merge m:1 cic2 using "`d2'"
keep if _merge==3
drop _merge

* --------- DEFINE TWO BIG GROUPS ----------
* Group 1: cic2 in {17,18,19}; Group 2: cic2 in {39,40,41}
gen byte biggrp = .
replace biggrp = 1 if inlist(cic2, 17, 18, 19)
replace biggrp = 2 if inlist(cic2, 39, 40, 41)
* 保留两大组样本
keep if inlist(biggrp, 1, 2)

label define BIGGRP 1 "Group 1: 17/18/19" 2 "Group 2: 39/40/41"
label values biggrp BIGGRP

* --------- FILTERS ----------
drop if es==.
drop if es2q==.

* --------- CORE VARIABLES ----------
gen markdowncd1      = 1 - (1/b_m)*es                          // a
gen mdcd2            = domesticint/importint
gen mdcd3            = (1/b_m)*es                               // b
gen markdownnonHicks = markdowncd1*mdcd2/mdcd3                  // t  (technology term)

* --------- Winsor by (biggrp × year) ----------
cap which winsor2
if _rc ssc install winsor2, replace
local v markdownnonHicks
winsor2 `v', trim cuts(2 98) by(biggrp year)
summ `v', detail

drop markdownnonHicks
rename markdownnonHicks_tr markdownnonHicks

preserve
* 现在我们要算中位数：按 biggrp-year 分组的中位数
bysort biggrp year: egen med_markdownnonHicks = median(markdownnonHicks)

* 我们只需要每个 biggrp-year 的唯一一行保存
keep biggrp year med_markdownnonHicks
duplicates drop biggrp year, force

sort biggrp year
save "markdown_median_figure.dta", replace
use "markdown_median_figure.dta", clear

twoway ///
    (connected med_markdownnonHicks year if biggrp==1, ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected med_markdownnonHicks year if biggrp==2, ///
        sort lcolor(red) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
    legend(order(1 "Textiles  (CIC2 17/18/19)" ///
                 2 "Electronics  (CIC2 39/40/41)") ///
          position(6) ring(1) rows(1) cols(2) size(small)) ///
    ytitle("Foreign-input–biased, non-Hicks-neutral term (median firm)") ///
    xtitle("Year") ///
    title("Evolution of foreign-input–biased technology (median firm)") ///
    yline(1, lpattern(shortdash) lcolor(gs8)) ///
    xlabel(, grid) ylabel(, grid) ///
    graphregion(color(white)) ///
    name(fig_median, replace)
graph export "markdown_fig_median.png", name(fig_median)   width(2400) replace

restore

preserve 
 * Revenue-weighted group-year means (one row per biggrp-year)
 collapse (mean) markdownnonHicks [aw=R], by(biggrp year)
 rename markdownnonHicks  w_markdownnonHicks   

twoway ///
    (connected w_markdownnonHicks year if biggrp==1, ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected w_markdownnonHicks year if biggrp==2, ///
        sort lcolor(red) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
       legend(order(1 "Textiles  (CIC2 17/18/19)" ///
                 2 "Electronics  (CIC2 39/40/41)") ///
          position(6) ring(1) rows(1) cols(2) size(small)) ///
    xtitle("Year") ///
    ytitle("Markdown (revenue-weighted mean)") ///
    title("Markdown, revenue-weighted means") ///
    name(fig_md_weighted, replace)
graph export "markdown_fig_mean.png", name(fig_md_weighted)   width(2400) replace
restore

* =========================
* 末尾追加：Median vs Weighted 同图（按行业分面）— 修正版（无嵌套 preserve）
* =========================
preserve
    * 若当前内存里尚无清洗后的 markdownnonHicks，则补算并 winsor
    cap confirm var markdownnonHicks
    if _rc {
        gen markdowncd1      = 1 - (1/b_m)*es
        gen mdcd2            = domesticint/importint
        gen mdcd3            = (1/b_m)*es
        gen markdownnonHicks = markdowncd1*mdcd2/mdcd3

        cap which winsor2
        if _rc ssc install winsor2, replace
        winsor2 markdownnonHicks, trim cuts(2 98) by(biggrp year)
        drop markdownnonHicks
        rename markdownnonHicks_tr markdownnonHicks
    }

    * 只保留绘图需要的变量，减少内存和 IO
    keep biggrp year markdownnonHicks R
    tempfile base t_med t_wgt

    * 备份当前数据
    quietly save `base', replace

    * --- 1) 组-年中位数 ---
    collapse (median) med_markdownnonHicks = markdownnonHicks, by(biggrp year)
    sort biggrp year
    quietly save `t_med'

    * --- 2) 组-年营收加权均值 ---
    use `base', clear
    collapse (mean) w_markdownnonHicks = markdownnonHicks [aw=R], by(biggrp year)
    sort biggrp year
    quietly save `t_wgt'

    * --- 3) 合并两条序列并作图 ---
    use `t_med', clear
    merge 1:1 biggrp year using `t_wgt', nogen

twoway ///
    (connected med_markdownnonHicks year, ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected w_markdownnonHicks year, ///
        sort lcolor(red) lpattern(dash) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
    by(biggrp, ///
        legend(on position(6) ring(1) ///
               symxsize(*0.7) keygap(*0.6)) ///
        note("") col(1) imargin(small)) ///
    legend(order(1 "Median" 2 "Revenue-weighted mean") ///
           position(6) ring(1) rows(1) cols(2)  size(small) region(lstyle(none))) ///
    xtitle("Year") ///
    ytitle("Foreign-input–biased, non-Hicks-neutral term") ///
    title("Median vs. revenue-weighted mean (by industry group)") ///
    yline(1, lpattern(shortdash) lcolor(gs8)) ///
    xlabel(, grid) ylabel(, grid) ///
    graphregion(color(white) margin(b=18)) ///
    name(fig_med_vs_wgt_bygrp, replace)
graph export "markdown_fig_med_vs_wgt_bygrp.png",  name(fig_med_vs_wgt_bygrp)  width(2400) replace

restore


save "Markdown_mean_figure.dta", replace