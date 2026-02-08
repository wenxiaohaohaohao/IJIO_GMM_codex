//使用原始数据,最大m:m匹配到07层面
cd"C:\Users\wangx\Downloads\工企\数据"
clear
use "C:\Users\wangx\Downloads\工企\数据\tariffnew.dta"
keep if year>=2002
keep if year<2007
rename hs6 hs2002
merge m:m hs2002 using "C:\Users\wangx\Downloads\工企\数据\hs02to96.dta"
drop _merge
drop hs2002

save part2.dta, replace

clear
use "C:\Users\wangx\Downloads\工企\数据\tariffnew.dta"
keep if year<=2001
save part1.dta, replace

clear
use "C:\Users\wangx\Downloads\工企\数据\tariffnew.dta"
keep if year==2007
rename hs6 hs2007
merge m:m hs2007 using "C:\Users\wangx\Downloads\工企\数据\hs07to96.dta"
drop _merge
drop hs2007

save part3.dta, replace

clear
use part3.dta
append using part2.dta
append using part1.dta

save finalimporttariff.dta,replace
erase part1.dta
erase part2.dta
erase part3.dta
