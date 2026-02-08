******************************************************************************
******************************************************************************
*****************************Non_Hicks tech************************************
******************************************************************************
******************************************************************************
clear all
set more off

* ===== 1) 读取数据 =====
capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


cd "$ROOT"
use "$DATA_WORK/mdnon-Hicks.dta", clear

* ===== 2) 如果 biggrp 是字符串，转成数值型便于画图 =====
capture confirm numeric variable biggrp
if _rc {
    encode biggrp, gen(biggrp_id)
    local GRPVAR biggrp_id
}
else {
    gen long biggrp_id = biggrp
    local GRPVAR biggrp_id
}

* （可选）给 biggrp 加上易读标签 —— 若你有明确两大组名称可在这里改
* 例如：1="G1: 纺织(17–19)", 2="G2: 电子(39–41)"
label define BIGLBL 1 "Group 1" 2 "Group 2", modify
label values `GRPVAR' BIGLBL

* ===== 3) 按 年×大类 计算均值/标准差/样本量 =====
preserve
collapse (mean) mean_aft=aft (sd) sd_aft=aft (count) N=aft, by(year `GRPVAR')

* 计算 95% 置信区间
gen double se_aft = sd_aft / sqrt(N)
gen double lb = mean_aft - 1.96*se_aft
gen double ub = mean_aft + 1.96*se_aft

* 确保按组和年份排序
sort `GRPVAR' year

* ===== 4) 同一张图叠加两条大类曲线 + 各自阴影置信带 =====
* 这里假设只有两个大类（常见情形：G1 与 G2）
levelsof `GRPVAR', local(grps)
if "`grps'" != "" {
    tokenize "`grps'"
    local g1 `1'
    local g2 `2'
}

twoway ///
    /// 组1：置信带 + 折线
    (rarea ub lb year if `GRPVAR'==`g1', color(navy%18) lcolor(navy%0)) ///
    (line  mean_aft year if `GRPVAR'==`g1', lcolor(navy) lwidth(medthick)) ///
    /// 组2：置信带 + 折线
    (rarea ub lb year if `GRPVAR'==`g2', color(maroon%18) lcolor(maroon%0)) ///
    (line  mean_aft year if `GRPVAR'==`g2', lcolor(maroon) lwidth(medthick)) ///
    , ///
    ytitle("Average AFT") ///
    xtitle("Year") ///
    title("Annual Average AFT by Big Group (with 95% CI)") ///
    legend(order(2 "`: label (BIGLBL) `g1''" 4 "`: label (BIGLBL) `g2''") pos(6) ring(0)) ///
    graphregion(color(white)) plotregion(margin(zero))

* 导出图片（可改为 .pdf/.tif）
graph export "$RES_FIG/aft_by_biggrp.png", replace
restore

	  

	   
*************************************************************
clear all
set more off

* 1) 读取
cd "$ROOT"
use "$DATA_WORK/mdnon-Hicks.dta", clear

* 2) biggrp 转为数值型 ID 便于分组
capture confirm numeric variable biggrp
if _rc {
    encode biggrp, gen(biggrp_id)
}
else {
    gen long biggrp_id = biggrp
}

* （可选）标签
label define BIGLBL 1 "Group 1" 2 "Group 2", modify
label values biggrp_id BIGLBL

* 3) 按 年×大类 取"中位数的 log(AFT)"
preserve
collapse (median) log_aft = aft, by(biggrp_id year)

* 4) 以 2000 为基期做指数、逐年增长、以及 2000→2007 累计增长
local BASEYEAR = 2000

* 基期 log 值（每个组唯一）
bysort biggrp_id: egen base_log = max(cond(year==`BASEYEAR', log_aft, .))

* 年度指数（基期=1）
gen double idx = exp(log_aft - base_log)

* 对应的"相对基期"的年度累计增长（到当年的累计 %）
gen double cum_from_base_pct = 100*(idx - 1)

* 逐年增长率：exp(Δlog)-1
xtset biggrp_id year
gen double dlog = log_aft - L.log_aft
gen double yoy_pct = 100*(exp(dlog) - 1)

* 终点（2007）累计增长率（每组一个数），写到每行或只留在末行都行
bysort biggrp_id (year): gen byte is_last = _n==_N
bysort biggrp_id: gen double cum_2000_2007_pct = 100*(idx[_N] - 1)
format cum_2000_2007_pct %9.2f

* 5) 画"相对基期指数"（两组同图）
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
    ytitle("Normalized Non-Neutral Technology") ///
    xtitle("Year") ///
    title("Normalized Median Non-Neutral Technology by Sector") ///
    graphregion(color(white) lstyle(solid) lcolor(black)) ///
    plotregion(fcolor(white) lstyle(solid) lcolor(black)) ///

graph export "$RES_FIG/aft_index_by_biggrp.png", width(2400) replace

restore
	   
* =========================
* 基于权重 R 的加权均值 + 基期指数（无 95% CI）
* 假设：aft 为 log(AFT)；biggrp 可能为字符串；R 可能缺失
* 时间范围：2000–2007（无缺失）
* =========================

clear all
set more off

* 1) 读取
cd "$ROOT"
use "$DATA_WORK/mdnon-Hicks.dta", clear

preserve
    * -- 0) 权重：R 缺失则退回等权 --
    capture confirm variable R
    if _rc {
        di as error "警告：未找到权重变量 R，将使用等权重。"
        gen double __w = 1
    }
    else {
        gen double __w = R
        replace __w = 1 if missing(__w)
    }

    * -- 1) biggrp 数值化 --
    capture confirm numeric variable biggrp
    if _rc {
        encode biggrp, gen(biggrp_id)
    }
    else {
        gen long biggrp_id = biggrp
    }
    label define BIGLBL 1 "Group 1" 2 "Group 2", modify
    label values biggrp_id BIGLBL

    * -- 2) 计算 年×组 的加权均值（log 尺度）--
    drop wx WX 
    gen double wx = __w * aft
    bys biggrp_id year: egen double W  = total(__w)
    bys biggrp_id year: egen double WX = total(wx)
    gen double mean_log = WX / W

    keep biggrp_id year mean_log
    duplicates drop biggrp_id year, force
    sort biggrp_id year

    * -- 3) 以 2000 为基期：指数与累计增长（指数化） --
    local BASEYEAR = 2000
    by biggrp_id: egen base_log = max(cond(year==`BASEYEAR', mean_log, .))

    * 指数（基期=1）
    gen double idx = exp(mean_log - base_log)

    * 到当年的"相对基期累计增长率"（％）
    gen double cum_from_base_pct = 100*(idx - 1)

    * 2000→2007 终点累计增长（每组一个数）
    bys biggrp_id (year): gen byte is_last = _n==_N
    bys biggrp_id: gen double cum_2000_2007_pct = 100*(idx[_N] - 1)
    format cum_2000_2007_pct %9.2f

    * -- 4) 作图（两组同图；无 CI 阴影） --
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
    ytitle("Normalized Non-Neutral Technology") ///
    xtitle("Year") ///
    title("Normalized Average Non-Neutral Technology by Sector") ///
    graphregion(color(white) lstyle(solid) lcolor(black)) ///
    plotregion(fcolor(white) lstyle(solid) lcolor(black)) ///
    name(fig_aft_wmean_index, replace)
* 导出
graph export "$RES_FIG/aft_wmean_index.png", name(fig_aft_wmean_index) width(2400) replace

