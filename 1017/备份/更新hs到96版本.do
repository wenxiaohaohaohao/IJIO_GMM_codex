//使用原始数据,最大m:m匹配到96层面
clear
use "D:\EPS数据库\清洗后数据库\海关数据库\中国海关企业数据库（firm-year-hs6）\中国海关企业数据库（firm-year-hs6）.dta"
rename hs6 hs2002
keep if year<=2007
merge m:m hs2002 using hs02to96.dta
//复原2001年之前的
replace hs6=hs2002 if year<2002
drop hs2002
rename hs6 hs2007
drop _merge
merge m:m hs2007 using hs07to96.dta
//复原2001年之前的
replace hs6=hs2007 if year<2007
drop hs2007
drop _merge
save 中国海关企业数据库（firm-year-hs6）v2.dta
