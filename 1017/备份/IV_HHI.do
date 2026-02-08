clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO"

use "D:\文章发表\欣昊\input markdown\IJIO\all_years_2000_2007.dta",clear
keep if expimp==1
drop if missing(value) | missing(year) | missing(firmid) | missing(hs6)

* 1) 企业进入年（基期）
bys firmid: egen baseyear = min(year)
gen isbase = (year==baseyear)

* 2) 只用基期数据算 country share
preserve
keep if isbase==1
collapse (sum) value, by(firmid country)

bys firmid: egen tot0 = total(value)
gen s0 = value/tot0 if tot0>0
gen s0sq = s0^2

bys firmid: egen HHI0_country = total(s0sq)
keep firmid HHI0_country
tempfile HHI0
save `HHI0', replace
restore

* 3) 回到全样本并合并 HHI0
merge m:1 firmid using `HHI0', nogen keep(match)

* 4) 制度冲击（举例：post2002）
gen post2002 = (year>=2002)

* 5) IV
gen Z_HHI_post = HHI0_country * post2002
label var Z_HHI_post "HHI0_country × Post2002"

save "D:\文章发表\欣昊\input markdown\IJIO\Z_HHI_post.dta", replace
