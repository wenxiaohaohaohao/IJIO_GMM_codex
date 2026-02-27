******************************************************************************
******************************************************************************
*****************************Non_Hicks tech************************************
******************************************************************************
******************************************************************************
clear all
set more off

capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_markdown_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
* ===== 1) 璇诲彇鏁版嵁 =====
cd "$ROOT"
use "$DATA_WORK/nonmdnon-Hicks", clear

* ===== 2) 濡傛灉 biggrp 鏄瓧绗︿覆锛岃浆鎴愭暟鍊煎瀷渚夸簬鐢诲浘 =====
capture confirm numeric variable biggrp
if _rc {
    encode biggrp, gen(biggrp_id)
    local GRPVAR biggrp_id
}
else {
    gen long biggrp_id = biggrp
    local GRPVAR biggrp_id
}

* 锛堝彲閫夛級缁?biggrp 鍔犱笂鏄撹鏍囩 鈥斺€?鑻ヤ綘鏈夋槑纭袱澶х粍鍚嶇О鍙湪杩欓噷鏀?* 渚嬪锛?="G1: 绾虹粐(17鈥?9)", 2="G2: 鐢靛瓙(39鈥?1)"
label define BIGLBL 1 "Group 1" 2 "Group 2", modify
label values `GRPVAR' BIGLBL

* ===== 3) 鎸?骞疵楀ぇ绫?璁＄畻鍧囧€?鏍囧噯宸?鏍锋湰閲?=====
preserve
collapse (mean) mean_aft=aft (sd) sd_aft=aft (count) N=aft, by(year `GRPVAR')

* 璁＄畻 95% 缃俊鍖洪棿
gen double se_aft = sd_aft / sqrt(N)
gen double lb = mean_aft - 1.96*se_aft
gen double ub = mean_aft + 1.96*se_aft

* 纭繚鎸夌粍鍜屽勾浠芥帓搴?sort `GRPVAR' year

* ===== 4) 鍚屼竴寮犲浘鍙犲姞涓ゆ潯澶х被鏇茬嚎 + 鍚勮嚜闃村奖缃俊甯?=====
* 杩欓噷鍋囪鍙湁涓や釜澶х被锛堝父瑙佹儏褰細G1 涓?G2锛?levelsof `GRPVAR', local(grps)
if "`grps'" != "" {
    tokenize "`grps'"
    local g1 `1'
    local g2 `2'
}

twoway ///
    /// 缁?锛氱疆淇″甫 + 鎶樼嚎
    (rarea ub lb year if `GRPVAR'==`g1', color(navy%18) lcolor(navy%0)) ///
    (line  mean_aft year if `GRPVAR'==`g1', lcolor(navy) lwidth(medthick)) ///
    /// 缁?锛氱疆淇″甫 + 鎶樼嚎
    (rarea ub lb year if `GRPVAR'==`g2', color(maroon%18) lcolor(maroon%0)) ///
    (line  mean_aft year if `GRPVAR'==`g2', lcolor(maroon) lwidth(medthick)) ///
    , ///
    ytitle("Average AFT") ///
    xtitle("Year") ///
    title("Annual Average AFT by Big Group (with 95% CI)") ///
    legend(order(2 "`: label (BIGLBL) `g1''" 4 "`: label (BIGLBL) `g2''") pos(6) ring(0)) ///
    graphregion(color(white)) plotregion(margin(zero))

* 瀵煎嚭鍥剧墖锛堝彲鏀逛负 .pdf/.tif锛?graph export "$RES_FIG/aft_by_biggrp.png", replace
restore

	  





	   
*************************************************************
clear all
set more off

* 1) 璇诲彇
cd "$ROOT"
use "$DATA_WORK/nonmdnon-Hicks", clear

* 2) biggrp 杞负鏁板€煎瀷 ID 渚夸簬鍒嗙粍
capture confirm numeric variable biggrp
if _rc {
    encode biggrp, gen(biggrp_id)
}
else {
    gen long biggrp_id = biggrp
}

* 锛堝彲閫夛級鏍囩
label define BIGLBL 1 "Group 1" 2 "Group 2", modify
label values biggrp_id BIGLBL

* 3) 鎸?骞疵楀ぇ绫?鍙?涓綅鏁扮殑 log(AFT)"
preserve
collapse (median) log_aft = aft, by(biggrp_id year)

* 4) 浠?2000 涓哄熀鏈熷仛鎸囨暟銆侀€愬勾澧為暱銆佷互鍙?2000鈫?007 绱澧為暱
local BASEYEAR = 2000

* 鍩烘湡 log 鍊硷紙姣忎釜缁勫敮涓€锛?bysort biggrp_id: egen base_log = max(cond(year==`BASEYEAR', log_aft, .))

* 骞村害鎸囨暟锛堝熀鏈?1锛?gen double idx = exp(log_aft - base_log)

* 瀵瑰簲鐨?鐩稿鍩烘湡"鐨勫勾搴︾疮璁″闀匡紙鍒板綋骞寸殑绱 %锛?gen double cum_from_base_pct = 100*(idx - 1)

* 閫愬勾澧為暱鐜囷細exp(螖log)-1
xtset biggrp_id year
gen double dlog = log_aft - L.log_aft
gen double yoy_pct = 100*(exp(dlog) - 1)

* 缁堢偣锛?007锛夌疮璁″闀跨巼锛堟瘡缁勪竴涓暟锛夛紝鍐欏埌姣忚鎴栧彧鐣欏湪鏈閮借
bysort biggrp_id (year): gen byte is_last = _n==_N
bysort biggrp_id: gen double cum_2000_2007_pct = 100*(idx[_N] - 1)
format cum_2000_2007_pct %9.2f

* 5) 鐢?鐩稿鍩烘湡鎸囨暟"锛堜袱缁勫悓鍥撅級
levelsof biggrp_id, local(gs)
tokenize "`gs'"
local g1 `1'
local g2 `2'

twoway ///
    (connected idx year if biggrp_id==`g1', ///
        sort lcolor(blue) lpattern(solid) lwidth(medium) ///
        msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
    (connected idx year if biggrp_id==`g2', ///
        sort lcolor(red) lpattern(dash) lwidth(medium) ///
        msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
, ///
    legend(order(1 "Textiles  (CIC2 17/18/19)" ///
                 2 "Electronics  (CIC2 39/40/41)") ///
          position(6) ring(1) rows(1) cols(2) size(small)) ///
    yline(1, lpattern(shortdash) lcolor(gs8)) ///
    ytitle("AFT Index (base=1 in `BASEYEAR')") ///
    xtitle("Year") ///
    title("Normalized Median log(AFT) by Big Group") ///
    graphregion(color(white))

graph export "$RES_FIG/aft_index_by_biggrp.png", width(2400) replace

restore
	   
* =========================
* 鍩轰簬鏉冮噸 R 鐨勫姞鏉冨潎鍊?+ 鍩烘湡鎸囨暟锛堟棤 95% CI锛?* 鍋囪锛歛ft 涓?log(AFT)锛沚iggrp 鍙兘涓哄瓧绗︿覆锛汻 鍙兘缂哄け
* 鏃堕棿鑼冨洿锛?000鈥?007锛堟棤缂哄け锛?* =========================

clear all
set more off

* 1) 璇诲彇
cd "$ROOT"
use "$DATA_WORK/nonmdnon-Hicks", clear

preserve
    * -- 0) 鏉冮噸锛歊 缂哄け鍒欓€€鍥炵瓑鏉?--
    capture confirm variable R
    if _rc {
        di as error "璀﹀憡锛氭湭鎵惧埌鏉冮噸鍙橀噺 R锛屽皢浣跨敤绛夋潈閲嶃€?
        gen double __w = 1
    }
    else {
        gen double __w = R
        replace __w = 1 if missing(__w)
    }

    * -- 1) biggrp 鏁板€煎寲 --
    capture confirm numeric variable biggrp
    if _rc {
        encode biggrp, gen(biggrp_id)
    }
    else {
        gen long biggrp_id = biggrp
    }
    label define BIGLBL 1 "Group 1" 2 "Group 2", modify
    label values biggrp_id BIGLBL

    * -- 2) 璁＄畻 骞疵楃粍 鐨勫姞鏉冨潎鍊硷紙log 灏哄害锛?-
    drop wx WX 
    gen double wx = __w * aft
    bys biggrp_id year: egen double W  = total(__w)
    bys biggrp_id year: egen double WX = total(wx)
    gen double mean_log = WX / W

    keep biggrp_id year mean_log
    duplicates drop biggrp_id year, force
    sort biggrp_id year

    * -- 3) 浠?2000 涓哄熀鏈燂細鎸囨暟涓庣疮璁″闀匡紙鎸囨暟鍖栵級 --
    local BASEYEAR = 2000
    by biggrp_id: egen base_log = max(cond(year==`BASEYEAR', mean_log, .))

    * 鎸囨暟锛堝熀鏈?1锛?    gen double idx = exp(mean_log - base_log)

    * 鍒板綋骞寸殑"鐩稿鍩烘湡绱澧為暱鐜?锛堬紖锛?    gen double cum_from_base_pct = 100*(idx - 1)

    * 2000鈫?007 缁堢偣绱澧為暱锛堟瘡缁勪竴涓暟锛?    bys biggrp_id (year): gen byte is_last = _n==_N
    bys biggrp_id: gen double cum_2000_2007_pct = 100*(idx[_N] - 1)
    format cum_2000_2007_pct %9.2f

    * -- 4) 浣滃浘锛堜袱缁勫悓鍥撅紱鏃?CI 闃村奖锛?--
    levelsof biggrp_id, local(gs)
    tokenize "`gs'"
    local g1 `1'
    local g2 `2'

    twoway ///
        (connected idx year if biggrp_id==`g1', ///
            sort lcolor(blue)   lpattern(solid) lwidth(medium) ///
            msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge)) ///
        (connected idx year if biggrp_id==`g2', ///
            sort lcolor(red) lpattern(dash)  lwidth(medium) ///
            msymbol(O) mcolor(red) mfcolor(none) msize(medlarge)) ///
    , ///
        legend(order(1 "Textiles  (CIC2 17/18/19)" ///
                 2 "Electronics  (CIC2 39/40/41)") ///
          position(6) ring(1) rows(1) cols(2) size(small)) ///
        yline(1, lpattern(shortdash) lcolor(gs8)) ///
        ytitle("AFT Index (weighted, base=1 in `BASEYEAR')") ///
        xtitle("Year") ///
        title("Weighted mean log(AFT): index (no CI)") ///
        graphregion(color(white)) ///
        name(fig_aft_wmean_index, replace)

restore

* 瀵煎嚭
graph export "$RES_FIG/aft_wmean_index.png", name(fig_aft_wmean_index) width(2400) replace



