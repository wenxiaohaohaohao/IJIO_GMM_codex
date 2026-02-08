clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\Non_hicks"


use "omega_xi_cic2_17.dta",clear
* 依次追加其它行业
append using "omega_xi_cic2_18.dta"
append using "omega_xi_cic2_19.dta"
append using "omega_xi_cic2_39.dta"
append using "omega_xi_cic2_40.dta"
append using "omega_xi_cic2_41.dta"

* 确认合并结果
describe
summarize omega_hat xi_hat

* 检查行业分布
tab cic2

* 保存合并后的完整 TFP 数据2002-2007 using Gmm
save "omega_xi_allindustries.dta", replace


use "firststage-nonhicks.dta",clear

* 3) 合并"各行业最终系数"
merge m:1 cic2 using "nonhicks_gmm_by_cic2_withSE.dta", keep(match) nogen
gen byte   const = 1

* 4) 用合并的 \hat{beta} 计算外推的 \hat{omega} = phi - X \hat{beta}
capture drop omega_ext
gen double omega_ext = . 
replace omega_ext = phi ///
    - ( b_c1*const + b_l*l + b_k*k + b_m*m + b_es*es + b_essq*es2q )

label var omega_ext "DLW omega (extrapolated to 2000–2007)"

* 5) 标记 2000–2001 为"外推区间"（便于诊断/作图）
gen byte extrap_pre0201 = inrange(year,2000,2001)
label var extrap_pre0201 "1 if 2000–2001 (beta extrapolation)"

* 6) 导出结果（可直接与原 2002–2007 的 omega_xi 合并）
keep firmid year cic2 omega_ext phi l k m es es2q
order firmid year cic2 omega_ext phi l k m es es2q
compress
save "omega_ext_2000_2007.dta", replace
di as result ">> 已生成外推后的 omega 到 omega_ext_2000_2007.dta"


keep if inrange(year,2000,2002)
rename omega_ext omega_hat
save "omega_ext_2000_2002.dta", replace


***************以2002年为基准对接
use "omega_xi_allindustries.dta", clear
keep if year==2002
keep firmid cic2 omega_hat
rename omega_hat omega2002_auth
tempfile AUTH2002
save `AUTH2002'

use "omega_ext_2000_2002.dta", clear
* 合并进"权威 2002"
merge m:1 firmid using `AUTH2002', keep(master match) nogen
* 计算"企业层差值（只在2002年有值）"
gen double delta_2002 = omega2002_auth - omega_hat if year==2002
* 生成"企业层平移量"：若该企业 2002 有匹配，用该差值；否则缺失
bys firmid: egen double adj_firm = mean(delta_2002)
* 生成"行业层（cic2）平均平移量"，用于兜底
bys cic2: egen double adj_cic2 = mean(delta_2002)
* 统一选择平移量：优先企业层，其次行业层，最后置0
gen double adj = adj_firm
replace adj = adj_cic2 if missing(adj)
replace adj = 0        if missing(adj)
* 对"2000–2002 整段"做一次平移
replace omega_hat = omega_hat + adj if inrange(year,2000,2002)
* 为了万无一失：2002 年直接强制等于权威值（如果有）
replace omega_hat = omega2002_auth if year==2002 & !missing(omega2002_auth)
* 保存对齐后的 2000–2002
keep firmid year cic2 omega_hat
tempfile EXT002
save `EXT002', replace
*-----------------------------
* 3) 与权威 2002–2007 合并成统一口径
*   （2002 年以权威集为准，避免重复）
*-----------------------------
use "omega_xi_allindustries.dta", clear      // 权威：2002–2007（含 2002）
append using `EXT002'

* 若担心 2002 重复，保留权威版本（假设权威集里 2002 都有）
bysort firmid year (omega_hat): gen _dup = _N
drop if year==2002 & _dup>1 & _n>1   // 简洁去重：保留排序第一条（通常是权威那条）

drop _dup
order firmid year cic2 omega_hat
sort firmid year
save "omega_spliced_2000_2007.dta", replace
di as result ">> 已完成拼接与对齐：omega_spliced_2000_2007.dta（2002=权威；00–01已平移对齐）"

* 先确认时间设定
xtset firmid year


*******************************  简单平均，没有权重unweight ********************************************
* 按年取均值（不分行业）
collapse (mean) mean_tfp=omega_hat (sd) sd_tfp=omega_hat (count) N=omega_hat, by(year)

list year mean_tfp sd_tfp N

* 简单折线图
twoway line mean_tfp year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average TFP") xtitle("Year") ///
    title("Annual Average TFP (All Industries)") ///
    legend(off)

* 构造均值 ± 1.96*SE
gen se_tfp = sd_tfp/sqrt(N)
gen lb = mean_tfp - 1.96*se_tfp
gen ub = mean_tfp + 1.96*se_tfp

* 折线 + 阴影
twoway (rarea ub lb year, color(gs12%40)) ///
       (line mean_tfp year, lcolor(navy) lwidth(medthick)), ///
       ytitle("Average TFP") xtitle("Year") ///
       title("Annual Average TFP with 95% CI") legend(off)


******************************************************************************
******************************************************************************
*****************************Non_Hicks tech************************************
******************************************************************************
******************************************************************************

use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\mdnon-Hicks.dta", clear   

*******************************  简单平均，没有权重unweight ********************************************
* 按年取均值（不分行业）
collapse (mean) mean_aft=aft (sd) sd_aft=aft (count) N=aft, by(year)

list year mean_aft sd_aft N

* 简单折线图
twoway line mean_aft year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average AFT") xtitle("Year") ///
    title("Annual Average AFT (All Industries)") ///
    legend(off)

* 构造均值 ± 1.96*SE
gen se_aft = sd_aft/sqrt(N)
gen lb = mean_aft - 1.96*se_aft
gen ub = mean_aft + 1.96*se_aft

* 折线 + 阴影
twoway (rarea ub lb year, color(gs12%40)) ///
       (line mean_aft year, lcolor(navy) lwidth(medthick)), ///
       ytitle("Average AFT") xtitle("Year") ///
       title("Annual Average AFT with 95% CI") legend(off)


*********************************有权重的 tfp*********************************

use "omega_spliced_2000_2007.dta", clear

tempfile tfp
save "`tfp'", replace

use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\Non_hicks\firststage-nonhicks.dta", clear

keep firmid year cic2 R
tempfile weights_R
save "`weights_R'", replace

* 1. 当年总权重
bys year: egen Rtot = total(R)

* 2. 行业份额
gen share = R/Rtot

* 回到 TFP，合并 R
use "`tfp'", clear
merge 1:1 firmid year cic2 using "`weights_R'", nogen keep(match)

*--------------------------------------------------------------*
* 2. 企业 → 行业×年份：用 R 做加权均值
*   两种写法都行：collapse + [aw=R]；或先算份额再加总
*   这里用 collapse（更简洁）
*--------------------------------------------------------------*
* 直接企业层面聚合到年度
collapse (mean) tfp_year = omega_hat [aw=R], by(year)


list year tfp_year 

* 简单折线图
twoway line tfp_year year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average TFP weighted ") xtitle("Year") ///
    title("Annual Average TFP weighted (All Industries)") ///
    legend(off)


*********************************有权重的 aft*********************************
use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\mdnon-Hicks.dta", clear   
* 直接企业层面聚合到年度
collapse (mean) aft_year = aft [aw=R], by(year)

list year aft_year

*--------------------------------------------------------------*
* 简单折线图
*--------------------------------------------------------------*
twoway line aft_year year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average AFT weighted") xtitle("Year") ///
    title("Annual Average AFT weighted (All Industries)") ///
    legend(off)


*******************************放在一起*********************************

********************************************************************************
* 目标：TFP 与 AFT（R 加权）同图；各自按"2000=1"，若该序列缺 2000 用自身最早年。
*       若基期 ≤ 0 或接近 0，则采用"差额比例"归一化，防止形状被比值扭曲。
********************************************************************************

********************************* TFP（加权） *********************************
use "omega_spliced_2000_2007.dta", clear
tempfile tfp
save "`tfp'", replace

use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\Non_hicks\firststage-nonhicks.dta", clear
keep firmid year cic2 R
tempfile weights_R
save "`weights_R'", replace

* 合并 R 到 TFP
use "`tfp'", clear
merge 1:1 firmid year cic2 using "`weights_R'", nogen keep(match)

* 确保 year 为数值
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,") force

* 企业 → 年度（R 加权）
collapse (mean) tfp_year = omega_hat [aw=R], by(year)
tempfile tfp_year
save "`tfp_year'", replace


********************************* AFT（加权） *********************************
use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\mdnon-Hicks.dta", clear
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,") force

collapse (mean) aft_year = aft [aw=R], by(year)
tempfile aft_year
save "`aft_year'", replace


************************* 合到一张表（仅为作图方便） *************************
use "`tfp_year'", clear
merge 1:1 year using "`aft_year'", nogen
sort year

* 选择各自基期（优先 2000，否则该序列最早年）
local basewant = 2000

* —— TFP 基期
local base_tfp = `basewant'
quietly count if year==`base_tfp' & !missing(tfp_year)
if (r(N)==0) {
    quietly summarize year if !missing(tfp_year), meanonly
    local base_tfp = r(min)
    di as txt "TFP：2000 不在样本，改用最早年份 " as res `base_tfp' as txt " 作为基期。"
}
quietly summarize tfp_year if year==`base_tfp', meanonly
scalar b_tfp = r(mean)

* —— AFT 基期
local base_aft = `basewant'
quietly count if year==`base_aft' & !missing(aft_year)
if (r(N)==0) {
    quietly summarize year if !missing(aft_year), meanonly
    local base_aft = r(min)
    di as txt "AFT：2000 不在样本，改用最早年份 " as res `base_aft' as txt " 作为基期。"
}
quietly summarize aft_year if year==`base_aft', meanonly
scalar b_aft = r(mean)

di as txt "基期检查： TFP base=" as res %9.4g b_tfp ///
           as txt "  |  AFT base=" as res %9.4g b_aft

********************************************************************************
* 稳健归一化：基期>0 用比值；基期<0 用差额比例；基期=0 用标准差做尺度
********************************************************************************

* —— 先清理旧变量
capture drop tfp_index aft_index tfp_dev aft_dev

* TFP 归一化
if (b_tfp>0) {
    gen tfp_index = tfp_year / b_tfp
}
else if (b_tfp<0) {
    gen tfp_index = 1 + (tfp_year - b_tfp)/abs(b_tfp)
}
else {
    * b_tfp==0，用样本标准差作为尺度，避免除以 0
    quietly summarize tfp_year, detail
    scalar sd_tfp = r(sd)
    if (sd_tfp<=1e-10) scalar sd_tfp = 1
    gen tfp_index = 1 + (tfp_year - b_tfp)/sd_tfp
}

* AFT 归一化
if (b_aft>0) {
    gen aft_index = aft_year / b_aft
}
else if (b_aft<0) {
    gen aft_index = 1 + (aft_year - b_aft)/abs(b_aft)
}
else {
    quietly summarize aft_year, detail
    scalar sd_aft = r(sd)
    if (sd_aft<=1e-10) scalar sd_aft = 1
    gen aft_index = 1 + (aft_year - b_aft)/sd_aft
}

label var tfp_index "TFP (base=`base_tfp' -> 1, robust)"
label var aft_index "AFT (base=`base_aft' -> 1, robust)"

********************************************************************************
* 作图（同轴对比）
********************************************************************************

twoway ///
  (connected tfp_index year, lcolor(blue) lpattern(solid) lwidth(medium) ///
      msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge) sort) ///
  (connected aft_index year,  lcolor(red)  lpattern(dash)  lwidth(medium) ///
      msymbol(O) mcolor(red)  mfcolor(none) msize(medlarge) sort), ///
  legend(order(1 "TFP" 2 "AFT") position(6) ring(1) cols(2) region(lstyle(none))) ///  
  ytitle("Index (each series normalized to its own base; base=1)") ///
  xtitle("Year") ///
  title("TFP vs AFT (R-weighted, robust normalization)") ///
  xlabel(2000(1)2007, grid) ///
  xscale(range(2000 2007)) ///
  ylabel(, grid) ///
 graphregion(color(white) lstyle(solid) lcolor(black)) ///
  plotregion(fcolor(white) lstyle(solid) lcolor(black))

* 可选导出
graph export "tfp_aft_index_weighted.png", replace width(1200)







