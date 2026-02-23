*******************************************************
* Counterfactual cost-share plots + decomposition table
* Two big groups instead of per-cic2 sectors
* Three curves coincide at base year (2000 or group first year)
* Update: Constant-Technology also fixes mdcd3 at base year (b0)
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
* --------- FILE PATHS ----------
cd "$ROOT"
local d1 "$DATA_WORK/firststageCD.dta"
local d2 "$RES_DATA/gmm_point_industry.dta"

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



* --------- CORE VARIABLES ----------
gen markdowncd1=b_x/b_m
gen mdcd2=domesticint/importint
gen markdownCD=markdowncd1*mdcd2
gen ratio_a = importint/domesticint
drop if ratio_a<0.01

save "$DATA_WORK/mdCD.dta", replace
* --------- Winsor by (biggrp × year) ----------
cap which winsor2
if _rc ssc install winsor2, replace
local v markdownCD
winsor2 `v', trim cuts(5 95) by(biggrp year)
summ `v', detail

drop markdownCD
rename markdownCD_tr markdownCD

preserve
* 现在我们要算中位数：按 biggrp-year 分组的中位数
bysort biggrp year: egen med_markdownCD = median(markdownCD)

* 我们只需要每个 biggrp-year 的唯一一行保存
keep biggrp year med_markdownCD
duplicates drop biggrp year, force

sort biggrp year
save "$DATA_WORK/markdown_median_figure.dta", replace
use "$DATA_WORK/markdown_median_figure.dta", clear

twoway ///
    (connected med_markdownCD year if biggrp==1, ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected med_markdownCD year if biggrp==2, ///
        sort lcolor(red) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
    legend(order(1 "Textiles  (CIC2 17/18/19)" ///
                 2 "Electronics  (CIC2 39/40/41)") ///
          position(6) ring(1) rows(1) cols(2) size(small)) ///
    ytitle("Median Foreign-Input Markdown") ///
    xtitle("Year") ///
    title("Evolution of Median Markdown by Sector") ///
    yline(1, lpattern(shortdash) lcolor(gs8)) ///
    xlabel(, grid) ylabel(, grid) ///
    graphregion(color(white) lstyle(solid) lcolor(black)) ///
    plotregion(fcolor(white) lstyle(solid) lcolor(black)) ///
    name(fig_median, replace)
graph export "$RES_FIG/markdown_fig_median.png", name(fig_median)   width(2400) replace

restore

preserve 
 * Revenue-weighted group-year means (one row per biggrp-year)
 collapse (mean) markdownCD [aw=R], by(biggrp year)
 rename markdownCD  w_markdownCD  

twoway ///
    (connected w_markdownCD year if biggrp==1, ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected w_markdownCD year if biggrp==2, ///
        sort lcolor(red) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
       legend(order(1 "Textiles  (CIC2 17/18/19)" ///
                 2 "Electronics  (CIC2 39/40/41)") ///
          position(6) ring(1) rows(1) cols(2) size(small)) ///
    xtitle("Year") ///
    ytitle("Weighted-Average Markdown ") ///
    title("Evolution of Average Markdown by Sector") ///
	  graphregion(color(white) lstyle(solid) lcolor(black)) ///
    plotregion(fcolor(white) lstyle(solid) lcolor(black)) ///
    name(fig_md_weighted, replace)
graph export "$RES_FIG/markdown_fig_mean.png", name(fig_md_weighted)   width(2400) replace
restore

* =========================
* 末尾追加：Median vs Weighted 同图（按行业分面）— 修正版（无嵌套 preserve）
* =========================
preserve
    * 若当前内存里尚无清洗后的 markdownCD，则补算并 winsor
    cap confirm var markdownCD
    if _rc {
gen markdowncd1=b_x/b_m
gen mdcd2=domesticint/importint
gen markdownCD=markdowncd1*mdcd2

        cap which winsor2
        if _rc ssc install winsor2, replace
        winsor2 markdownCD, trim cuts(5 95) by(biggrp year)
        drop markdownCD
        rename markdownCD_tr markdownCD
    }

    * 只保留绘图需要的变量，减少内存和 IO
    keep biggrp year markdownCD R
    tempfile base t_med t_wgt

    * 备份当前数据
    quietly save `base', replace

    * --- 1) 组-年中位数 ---
    collapse (median) med_markdownCD = markdownCD, by(biggrp year)
    sort biggrp year
    quietly save `t_med'

    * --- 2) 组-年营收加权均值 ---
    use `base', clear
    collapse (mean) w_markdownCD = markdownCD [aw=R], by(biggrp year)
    sort biggrp year
    quietly save `t_wgt'

    * --- 3) 合并两条序列并作图 ---
    use `t_med', clear
    merge 1:1 biggrp year using `t_wgt', nogen
	capture label drop BIGLBL
label define BIGLBL 1 "Textiles (CIC2 17/18/19)" 2 "Electronics (CIC2 39/40/41)"
label values biggrp BIGLBL


twoway ///
    (connected med_markdownCD year, ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected w_markdownCD year, ///
        sort lcolor(red) lpattern(dash) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
    by(biggrp, ///
        legend(on position(6) ring(2) ///
               symxsize(*0.7) keygap(*0.6)) ///
        note("") col(1) imargin(small) ///
        title("Median vs. Average Markdown by Sector")) ///
    legend(order(1 "Median Markdown" 2 "Weighted-Average Markdown") ///
           position(6) ring(2) rows(1) cols(2) size(small) region(lstyle(none))) ///
    xtitle("Year") ///
    ytitle("Markdown") ///
    xlabel(, grid) ylabel(, grid) ///
    graphregion(color(white) lstyle(solid) lcolor(black)) ///
    plotregion(fcolor(white) lstyle(solid) lcolor(black)) ///
    name(fig_med_vs_wgt_bygrp, replace)

graph export "$RES_FIG/markdown_fig_med_vs_wgt_bygrp.png", ///
    name(fig_med_vs_wgt_bygrp) width(2400) replace

restore



save "$DATA_WORK/Markdown_mean_figure.dta", replace