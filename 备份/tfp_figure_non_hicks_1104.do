clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"

*******************************************************************************
//直接计算omega
*******************************************************************************
use "firststage-nonhicks.dta",clear

* 3) 合并"各行业最终系数"
merge m:1 cic2 using "gmm_point_industry.dta", keep(match) nogen
* 1) 常数
capture confirm variable const
if _rc gen byte const = 1

* 2) 控制项贡献：age + 所有制(外企/民企；基类=国企)
gen double ctrl_hat = 0

capture confirm variable b_lnage
if !_rc replace ctrl_hat = ctrl_hat + b_lnage * lnage

foreach c in 2 3 {
    capture confirm variable firmcat_`c'
    if !_rc {
        capture confirm variable b_firmcat_`c'
        if !_rc replace ctrl_hat = ctrl_hat + b_firmcat_`c' * firmcat_`c'
    }
}

* 3) 生产项贡献：常数 + L + K + M + S^2（es 与 es2q）
gen double prod_hat = b_const*const ///
                    + b_l*l + b_k*k + b_m*m + b_es*es + b_essq*es2q

* 4) 外推 \hat{omega} ：phi - 生产项 - 控制项
capture drop omega_hat
gen double omega_hat = phi - prod_hat - ctrl_hat
label var omega_hat "DLW omega (extrapolated; controls: age+ownership)"
label var ctrl_hat  "contrib(age, firmcat_2, firmcat_3)"
label var prod_hat  "contrib(const+L+K+M+S^2)"

save "omega_spliced_2000_2007.dta",replace

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
	
preserve 

collapse (median) aft_year = aft, by(year)

list year aft_year

*--------------------------------------------------------------*
* 简单折线图
*--------------------------------------------------------------*
twoway line aft_year year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average AFT weighted") xtitle("Year") ///
    title("Annual Average AFT weighted (All Industries)") ///
    legend(off)

restore

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
capture drop tfp_index aft_index
gen double tfp_index = exp(tfp_year - b_tfp)
gen double aft_index = exp(aft_year - b_aft)

label var tfp_index "TFP index (base=`base_tfp' → 1)"
label var aft_index "AFT index (base=`base_aft' → 1)"

save tfp_aft_annual_rate.dta,replace 


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


use tfp_aft_annual_rate.dta,clear 
* TFP
sum tfp_index if year==2000
scalar tfp0 = r(mean)
sum tfp_index if year==2007
scalar tfp7 = r(mean)

scalar tfp_cagr = (tfp7/tfp0)^(1/7) - 1
display "TFP 年均增长率 = " 100*tfp_cagr "%"

* AFT
sum aft_index if year==2000
scalar aft0 = r(mean)
sum aft_index if year==2007
scalar aft7 = r(mean)

scalar aft_cagr = (aft7/aft0)^(1/7) - 1
display "AFT 年均增长率 = " 100*aft_cagr "%"

************************************************************************
*********************分行业的年平均增长率*************************************************************************************************************
/*******************************************************************************
* 分行业（cic2）的年均增长率：TFP 与 AFT
* 需求：使用与前文相同两份"企业层面"原始数据 + 收入权重 R
*******************************************************************************/

*--- 1) 准备：从企业层面聚合到 行业×年份（权重=R） ------------------------*
* TFP：用你之前的数据源（含 omega_hat, firmid, cic2, year, R）
preserve
    use "omega_spliced_2000_2007.dta", clear
    merge 1:1 firmid year cic2 using "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\Non_hicks\firststage-nonhicks.dta", ///
        keepusing(R) nogen keep(match)
    drop if missing(omega_hat, R, cic2, year) | R<=0
    collapse (mean) tfp_ln = omega_hat [aw=R], by(cic2 year)   // 行业×年 加权均值（对数）
    tempfile tfp_cy
    save "`tfp_cy'", replace
restore

* AFT：用 mdnon-Hicks 源（含 aft, firmid, cic2, year, R）
preserve
    use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\mdnon-Hicks.dta", clear
    drop if missing(aft, R, cic2, year) | R<=0
    collapse (mean) aft_ln = aft [aw=R], by(cic2 year)         // 行业×年 加权均值（对数）
    tempfile aft_cy
    save "`aft_cy'", replace
restore

* 合并到同一张行业×年表
use "`tfp_cy'", clear
merge 1:1 cic2 year using "`aft_cy'", nogen

*--- 2) 为每个行业选择基期：优先 2000，否则该行业最早年 ---------------------*
local basewant = 2000

bys cic2: egen first_year = min(year)
bys cic2: egen last_year  = max(year)

* 基期年份（优先2000，否则最早年）
bys cic2: egen base_year_tfp = max(cond(year==`basewant' & !missing(tfp_ln), year, .))
replace base_year_tfp = first_year if missing(base_year_tfp)

bys cic2: egen base_year_aft = max(cond(year==`basewant' & !missing(aft_ln), year, .))
replace base_year_aft = first_year if missing(base_year_aft)

* 基期的对数水平
bys cic2: egen tfp_base_ln = max(cond(year==base_year_tfp, tfp_ln, .))
bys cic2: egen aft_base_ln = max(cond(year==base_year_aft, aft_ln, .))

*--- 3) 行业指数（基期=1）：exp(ln_t - ln_base) -------------------------------*
gen double tfp_index_cy = exp(tfp_ln - tfp_base_ln) if !missing(tfp_ln, tfp_base_ln)
gen double aft_index_cy = exp(aft_ln - aft_base_ln) if !missing(aft_ln, aft_base_ln)

label var tfp_index_cy "TFP index by sector-year (base=1)"
label var aft_index_cy "AFT index by sector-year (base=1)"

*--- 4) 行业年均增长率（CAGR）：以各自基期→末期 ------------------------------*
* 年数（末期-基期）
gen years_tfp = last_year - base_year_tfp
gen years_aft = last_year - base_year_aft

* 末期指数（=该行业最后一年）
bys cic2: egen tfp_last = max(cond(year==last_year, tfp_index_cy, .))
bys cic2: egen aft_last = max(cond(year==last_year, aft_index_cy, .))

* CAGR： (last/base)^(1/years)-1；base=1 故为 last^(1/years)-1
gen double tfp_cagr = tfp_last^(1/years_tfp) - 1 if years_tfp>0 & tfp_last>0
gen double aft_cagr = aft_last^(1/years_aft) - 1 if years_aft>0 & aft_last>0

*--- 5) 逐年对数增速的行业均值（做交叉校验，可与 CAGR 对照） ------------------*
xtset cic2 year, yearly
gen double dlog_tfp = tfp_ln - L.tfp_ln if !missing(tfp_ln, L.tfp_ln)
gen double dlog_aft = aft_ln - L.aft_ln if !missing(aft_ln, L.aft_ln)

bys cic2: egen mean_dlog_tfp = mean(dlog_tfp)
bys cic2: egen mean_dlog_aft = mean(dlog_aft)

*--- 6) 输出行业层面的结果表 --------------------------------------------------*
preserve
    keep cic2 base_year_tfp last_year years_tfp tfp_cagr mean_dlog_tfp ///
         base_year_aft last_year years_aft aft_cagr mean_dlog_aft
    bys cic2: keep if _n==1

    gen tfp_cagr_pct = 100*tfp_cagr
    gen aft_cagr_pct = 100*aft_cagr
    gen mean_tfp_pct = 100*(exp(mean_dlog_tfp)-1)
    gen mean_aft_pct = 100*(exp(mean_dlog_aft)-1)

    order cic2 base_year_tfp last_year years_tfp tfp_cagr tfp_cagr_pct mean_dlog_tfp mean_tfp_pct ///
                base_year_aft            years_aft aft_cagr aft_cagr_pct mean_dlog_aft mean_aft_pct

    label var tfp_cagr_pct "TFP CAGR (%)"
    label var aft_cagr_pct "AFT CAGR (%)"
    label var mean_tfp_pct "Mean annual % (from log)"
    label var mean_aft_pct "Mean annual % (from log)"

    * 查看 & 保存
    list in 1/5, abbrev(16) noobs
    save "sector_cagr_tfp_aft.dta", replace
restore

di as txt "已生成分行业年均增长率结果：sector_cagr_tfp_aft.dta"

*--- 6) 精简输出：只保留 cic2 + CAGR 百分比 -------------------------------*
use "sector_cagr_tfp_aft.dta", clear
preserve
    keep cic2 tfp_cagr_pct aft_cagr_pct
    bys cic2: keep if _n==1   // 每行业只留一条

    order cic2 tfp_cagr_pct aft_cagr_pct
    label var tfp_cagr_pct "TFP CAGR (%)"
    label var aft_cagr_pct "AFT CAGR (%)"

    * 浏览前20个行业
    list in 1/6, abbrev(16) noobs

    * 保存精简结果
    save "sector_cagr_tfp_aft_slim.dta", replace
restore

di as txt "精简版结果已保存：sector_cagr_tfp_aft_slim.dta"
use "sector_cagr_tfp_aft_slim.dta", clear





