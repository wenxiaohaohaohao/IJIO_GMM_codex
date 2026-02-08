****************************************************
* Build two IVs in one script:
* (1) Z_HHI_post  = HHI0_country × post2002
* (2) Z_tariff    = sum_h share0(h) × tariff(h,t) /100
* Output: firmid-year with both IVs
****************************************************

clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO"

****************************************************
* 0) Load once: imports only, drop missings
****************************************************
use "D:\文章发表\欣昊\input markdown\IJIO\all_years_2000_2007.dta", clear
keep if expimp==1
drop if missing(value) | missing(year) | missing(firmid) | missing(hs6)

bys firmid: egen entryyear = min(year)
gen entrant2002 = (entryyear>=2002)

count
local N = r(N)
count if entrant2002==1
local N_post = r(N)

di "Share of firm-year obs from entrants >=2002 = " %6.3f (`N_post'/`N')

preserve
    keep firmid entrant2002
    duplicates drop firmid, force

    count
    local F = r(N)

    count if entrant2002==1
    local F_post = r(N)

    di "Share of firms entered >=2002 = " ///
       %6.3f (`F_post' / `F')
restore

****************************************************
* 1) HHI0_country (baseyear = firm's first year)
*    then build firm-year Z_HHI_post
****************************************************
* baseyear at firm level
bys firmid: egen baseyear = min(year)
gen isbase = (year==baseyear)

* ---- firm-level HHI0 from baseyear country shares ----
preserve
    keep if isbase==1
    drop if missing(country)

    * baseyear: firm-country import value
    collapse (sum) value0=value, by(firmid country)

    * shares within firm
    bys firmid: egen tot0 = total(value0)
    gen s0   = value0/tot0 if tot0>0
    gen s0sq = s0^2

    * HHI0_country = sum s0^2
    bys firmid: egen HHI0_country = total(s0sq)

    keep firmid HHI0_country
    duplicates drop
    tempfile HHI0
    save `HHI0', replace
restore

* ---- firm-year Z_HHI_post dataset ----
preserve
    keep firmid year baseyear
    duplicates drop firmid year, force

    merge m:1 firmid using `HHI0', nogen
    * 如果某些 firm 在基期没有 country（极少数），HHI0_country 可能缺失：
    replace HHI0_country = . if missing(HHI0_country)

    gen post2002   = (year>=2002)
    gen Z_HHI_post = HHI0_country * post2002
    label var Z_HHI_post "HHI0_country × Post2002"

    keep firmid year Z_HHI_post HHI0_country post2002
    duplicates drop firmid year, force
    tempfile ZHHI
    save `ZHHI', replace
restore


****************************************************
* 2) Tariff IV: Z_tariff = sum_h share0(h)*tariff(h,t)/100
*    share0(h) uses firm's baseyear (first year), not fixed 2000
****************************************************

* ---- collapse imports to firm-year-hs6 value ----
collapse (sum) value=value, by(firmid year hs6)

* ---- baseyear shares (firm-hs6) from firm's first year ----
bys firmid: egen baseyear2 = min(year)

preserve
    keep if year==baseyear2
    bys firmid: egen tot0 = total(value)
    gen share0 = value/tot0 if tot0>0

    keep firmid hs6 share0
    duplicates drop firmid hs6, force
    tempfile SHARE0
    save `SHARE0', replace
restore

* ---- prep tariff table: unique (year, hs6) ----
preserve
    use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\关税数据\finalimporttariff.dta", clear
    drop if missing(year) | missing(hs6) | missing(tariff)

    * 如果 using 数据里 year-hs6 不唯一：用均值聚合成唯一
    bysort year hs6: egen tariff_u = mean(tariff)
    bysort year hs6: keep if _n==1
    drop tariff
    rename tariff_u tariff

    tempfile TARIFF
    save `TARIFF', replace
restore

* ---- merge tariff and base shares ----
merge m:1 year hs6 using `TARIFF', keep(match) nogen
merge m:1 firmid hs6 using `SHARE0', nogen

* share0 缺失表示"基期没买过该 hs6"，权重=0
replace share0 = 0 if missing(share0)

* ---- compute firm-year tariff exposure ----
gen z = share0 * tariff
bys firmid year: egen Z_tariff = total(z)
replace Z_tariff = Z_tariff/100
label var Z_tariff "Baseyear hs6 share × tariff path (scaled by /100)"

keep firmid year Z_tariff
duplicates drop firmid year, force
tempfile ZTAR
save `ZTAR', replace


****************************************************
* 3) Combine both IVs into one firm-year dataset
****************************************************
use `ZTAR', clear
merge 1:1 firmid year using `ZHHI', nogen

* 输出一个统一的 firm-year IV 文件
save "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks\firm_year_IVs_Ztariff_ZHHI.dta", replace
****************************************************
* DONE
****************************************************
