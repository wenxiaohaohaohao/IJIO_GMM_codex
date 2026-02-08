clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO"

use "D:\文章发表\欣昊\input markdown\IJIO\all_years_2000_2007.dta",clear
keep if expimp==1
drop if missing(value) | missing(year) | missing(firmid) | missing(hs6)
collapse (sum) value, by(firmid year hs6)


bys firmid: egen entryyear = min(year)
gen entrant2002 = (entryyear>=2002)

count
local N = r(N)
count if entrant2002==1
local N_post = r(N)

di "Share of firm-year obs from entrants >=2002 = " %6.3f (`N_post'/`N')

preserve
    bys firmid: egen entryyear = min(year)
    gen entrant2002 = (entryyear>=2002)

    keep firmid entrant2002
    duplicates drop firmid, force

    count
    local F = r(N)

    count if entrant2002==1
    local F_post = r(N)

    di "Share of firms entered >=2002 = " ///
       %6.3f (`F_post' / `F')
restore

*------ 基期 share：用 2000 年
preserve
bysort firmid: egen baseyear = min(year)
keep if year==baseyear
bysort firmid: egen tot0 = total(value)
gen share0 = value/tot0 if tot0>0
keep firmid hs6 share0
tempfile SHARE0
save `SHARE0', replace
restore

preserve
use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\关税数据\finalimporttariff.dta",clear
drop if missing(year) | missing(hs6) | missing(tariff)
duplicates report year hs6
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


*------ 被动暴露度：sum_h share0(h)*tariff(h,t) ------
gen z = share0 * tariff
bysort firmid year: egen Z_tariff = total(z)
gen Z_tariff_iv = Z_tariff/100

keep firmid year Z_tariff_iv
rename Z_tariff_iv Z_tariff
duplicates drop
save "D:\文章发表\欣昊\input markdown\IJIO\firm_year_Z_tariff_base2000.dta", replace





