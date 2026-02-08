clear all
set more off
capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"


use "$DATA_RAW/all_years_2000_2007.dta",clear
keep if expimp==1
drop if missing(value) | missing(year) | missing(firmid) | missing(hs6)
collapse (sum) value, by(firmid year hs6 tradetype)
keep if inlist(tradetype, 1, 2)
*==============================================================*
* 二、构造基期结构 α_ij  —— 完全按照 Yu 的做法               *
*   思路：                                                     *
*   1) 只用普通贸易 (tradetype==1) 的进口额计算基期结构       *
*   2) 基期 = 企业"首次出现的年份"（企业异质性体现在这一年）  *
*   3) 对每个企业，把基期普通进口按 HS6 做 share              *
*   4) 得到 α_ij = value_ij0 / Σ_j value_ij0                  *
*==============================================================*
preserve
keep if tradetype == 1
bysort firmid: egen baseyear = min(year)
keep if year==baseyear
bysort firmid: egen tot0 = total(value)
* 基期权重 α_ij：某HS6在基期的普通进口额 / 企业基期普通进口额
gen share0 = value/tot0 if tot0>0
keep firmid hs6 share0
tempfile SHARE0
save `SHARE0', replace
restore

preserve
use "$DATA_RAW/finalimporttariff.dta",clear
drop if missing(year) | missing(hs6) | missing(tariff)

bysort year hs6: egen tariff_u = mean(tariff)
bysort year hs6: keep if _n==1
drop tariff
rename tariff_u tariff
tempfile finalimporttariff
save `finalimporttariff', replace
restore

*------ 合并关税 + 合并基期权重 ------
merge m:1 year hs6 using `finalimporttariff', keep(match) nogen
merge m:1 firmid hs6 using `SHARE0', nogen
drop if tariff==.
replace share0 = 0 if missing(share0)
* 构造"有效关税"：
*   - 普通贸易：用实际关税 tariff
*   - 加工贸易：视为免税，设为 0
gen tariff_eff = tariff
replace tariff_eff = 0 if tradetype == 2
replace tariff_eff = 0 if missing(tariff_eff)

*==============================================================*
* 五、计算企业层面的 input tariff 指数 λ_it                   *
*   λ_it = Σ_j α_ij * T_jt                                     *
*   其中 α_ij 不随时间变化，T_jt 随年份变化 ⇒ λ_it 是时间变的  *
*==============================================================*

gen z = share0 * tariff_eff

bysort firmid year: egen lambda_input = total(z)

* 如果你希望把单位从"百分点"换算成小数，可以除以 100：
gen lambda_input_dec = lambda_input/100

* 保留企业–年份层面的指数（避免重复）
keep firmid year lambda_input lambda_input_dec
duplicates drop

* 存成一个干净的数据文件，后面可以直接 merge 用
save "$DATA_WORK/OLStariff_yu_style.dta", replace

*==============================================================*
* （可选）六、顺手生成两个加工贸易变量：dummy & share         *
*   1) processing_dummy_it：当年是否有加工进口                  *
*   2) processing_share_it：当年加工进口额 / 总进口额           *
*   这两个变量在回归里通常与 λ_it 交互使用                      *
*==============================================================*

use "$DATA_RAW/all_years_2000_2007.dta", clear
keep if expimp == 1
drop if missing(firmid) | missing(year) | missing(hs6) | missing(value)
collapse (sum) value, by(firmid year hs6 tradetype)
keep if inlist(tradetype,1,2)

* 总进口额 & 加工进口额
bysort firmid year: egen import_total = total(value)
bysort firmid year: egen import_proc  = total(value) if tradetype==2

* 聚合到 firm-year
bysort firmid year: keep if _n==1
replace import_proc = 0 if missing(import_proc)

gen processing_dummy = (import_proc > 0)
gen processing_share = import_proc / import_total if import_total>0

keep firmid year processing_dummy processing_share
save "$DATA_WORK/processing_vars_yu_style.dta", replace

