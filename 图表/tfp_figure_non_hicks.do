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

* 保存合并后的完整 TFP 数据
save "omega_xi_allindustries.dta", replace
********************************************

use "omega_xi_allindustries.dta", clear

//merge 1:1 firmid year  using "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\图表\mdnon-Hicks.dta"


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

