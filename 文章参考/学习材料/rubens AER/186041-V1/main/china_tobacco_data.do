/*	Market Structure, Oligopsony Power, and Productivity
						(Michael Rubens, UCLA)

	- DATASET COMPILATION AND CLEANING - 
============================================================================*/
 
cd "$station"
clear
  
/* 1. Load and clean NBS ASIF Dataset */

set more off
set matsize 10000
clear

use ./data/nbsdata/master, clear		// this is the NBS ASIF dataset from Brandt, Van Biesebroeck, Wang, Zhang (AER, 2017)
 
* deflate all monetary variables

drop inputdefl // wrong input deflators in original files - need corrected deflators from AER corrigendum
merge m:1 cic_adj year using ./data/nbsdata/simple_correction_input_deflators
drop if _merge==2 
drop _merge
 
rename (deflator_input) (inputdefl)

gen dprofit = profit/outputdefl*100
gen drevenue = revenue/outputdefl*100
gen dinput = input_imputed1/inputdefl*100
gen dwage = wage/outputdefl*100
gen dnonwage = nonwage/outputdefl*100
gen dexport = export/outputdefl*100

* drop unnecessary variables and observations

drop export
rename (year firm drevenue dprofit dwage dnonwage real_cap dinput employment dexport) (yr fid rev prof w nw k m emp export)	// use deflated variables

label var yr "Year"
label var fid "Firm identifier"
label var rev "Revenue (deflated)"
label var prof "Profit (deflated)"
label var w "Wage bill (deflated)"
label var nw "Non-wage benefits (deflated)"
label var k "Real capital"
label var m "Intermediate inputs (deflated)"
label var emp "# Employees"

drop profit wage nonwage /*name*/ legal_person bdat area_code phone revenue // don't need these variables

gen uw=w/emp					
label var uw "Wage per worker (deflated)"

drop if yr>2007 | yr==.		// focus on 1999-2006 because product quantities unobserved outside this range

foreach var of varlist m rev w nw k  emp uw{
gen l`var' = ln(`var')		// logs
}

gen rev_usd = rev*1000/8.27			// currency unit = 1000 RMB = 120 USD in 2008. Only used for interpretation
label var rev_usd "Revenue (USD), deflated"

gen dexp = export>0
gen pctexp = export/rev
label var dexp "Export dummy"
label var pctexp "Export share of revenue"

/* 2. Industry and location codes */

* drop duplicates in HS CIC (industry codes) crosswalk 
preserve
use ./data/nbsdata/HS-CIC, clear 
/*
old code that randomly dropped HS codes that were duplicate within CIC codes. Used to generate 'CIC-HS'
use ./data/nbsdata/HS-CIC, clear		// from Brandt et al (2017)

qui bys cic_adj:  gen dup = cond(_N==1,0,_n)	// this function randomly picks which duplicate to keep and which to drop. 
drop if dup>1
*/

* new code:

duplicates tag cic_adj , gen(duptag)
sort cic_adj hs02_6 hs96_6
bys cic_adj: gen dup = _n
drop if dup>1
drop dup duptag 
save ./tempfiles/HS-CIC_nodup, replace
restore

* merge HS codes to CIC codes in data
*merge m:1 cic_adj using ./data/nbsdata/CIC-HS
merge m:1 cic_adj using ./tempfiles/HS-CIC_nodup
drop if _merge==2
drop _merge

tostring hs02_6, gen(hs02_6s)	// six digit HS code

forvalues m = 2(2)4 {
gen hs02_`m's = substr(hs02_6s,1,`m')
destring hs02_`m's, gen(hs02_`m')
}

gen dtob = hs02_2 == 24 		// tobacco industry dummy
gen dq6 = substr(dq,1,6)

gen year = yr

* tax variables

gen stax = va_tax/rev	// tax rate
gen lstax = log(stax)
 
// export activity in other industries within the same county

preserve
drop if dtob==1
bys dq6 yr: egen export_ot = sum(export)
bys dq6 yr: egen rev_ot = sum(rev)
gen pctexp_ot = export_ot/rev_ot
bys dq6 yr: egen dexp_ot = sum(dexp)
collapse dexp_ot pctexp_ot, by(dq6 yr)
save ./tempfiles/data_otherind, replace
restore

merge m:1 dq6 yr using ./tempfiles/data_otherind, nogen
drop dq6

keep if dtob==1

sum dexp_ot pctexp_ot 
 
 
/* 3. NBS Product-level quantity dataset */

gen open = emp~=.
preserve
keep if dtob==1		
collapse(sum) open, by(FRDM yr)
save ./tempfiles/firmids_tobacco, replace	// firm identifiers of tobacco firms, needed in quantity data construction program
restore

keep if dtob==1		// keep only the tobacco industry
drop dtob

* Transform monthly product-level quantity files from .txt to .dta format
* Only need december files - these contain the annual aggregates

preserve
local y = "00"			// 1999 and 2000
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8 v9)(FRDM firm_name zipcode productcode productname qm qcum qmprev qcumprev)
save "./tempfiles/q`y'.dta", replace

local y = "01"			// 2000 and 2001
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8 v9)(FRDM firm_name zipcode productcode productname qm qcum qmprev qcumprev)
drop v10
save "./tempfiles/q`y'.dta", replace

local y = "02"			// 2001 and 2002
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8 v9)(FRDM firm_name zipcode productcode productname qm qcum qmprev qcumprev)
save "./tempfiles/q`y'.dta", replace

local y = "03"			// 2002 and 2003
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8)(FRDM firm_name productcode productname qm qcum qmprev qcumprev)
tostring productcode,  format( %05.0f) replace		
drop v9
save "./tempfiles/q`y'.dta", replace

local y = "04"			// 2003 and 2004
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8 v9)(FRDM firm_name productcode productname unit qm qcum qmprev qcumprev)
tostring productcode,  format( %05.0f) replace		
drop v10 v11
save "./tempfiles/q`y'.dta", replace

local y = "05"			// 2004 and 2005
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8 v9)(FRDM firm_name productcode productname unit qm qcum qmprev qcumprev)
drop v10 v11
tostring productcode,  format( %05.0f) replace		
*keep if unit=="¶Ö "
save "./tempfiles/q`y'.dta", replace

local y = "06"			// 2005 and 2006
import delimited using "./data/physical quantity/qycp`y'12.txt",  stringcols(1 4) clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6 v7 v8 v9)(FRDM firm_name productcode productname unit qm qcum qmprev qcumprev)
tostring productcode,  format( %05.0f) replace		
save "./tempfiles/q`y'.dta", replace
 
****************************************

* Merge all the annual quantity files into a single .dta file
 
foreach y in "00" "01" "02" "03" {			// years 1999-2003
use "./tempfiles/q`y'", clear
drop qm qmprev
rename (qcum qcumprev) (q q_lag)
label var q "Output quantity"
label var q_lag "Output quantity, last year"
collapse(sum) q q_lag, by(FRDM productcode)
gen yr = 2000+`y'
save "./tempfiles/q`y'", replace
}

foreach y in  "04" "05" "06" {			// years 2004-2006
use "./tempfiles/q`y'", clear
drop qm qmprev
rename (qcum qcumprev) (q q_lag)
label var q "Output quantity"
label var q_lag "Output quantity, last year"
collapse(sum) q q_lag, by(FRDM productcode unit)
gen yr = 2000+`y'
save "./tempfiles/q`y'", replace
}

use "./tempfiles/q00", clear

foreach y in "01" "02" "03" "04" "05" "06"{
merge m:1 FRDM productcode yr using "./tempfiles/q`y'", nogen		// product descriptions
}

save "./tempfiles/china_quantities_allproduct", replace

egen fpid = group(FRDM productcode)
drop if productcode=="" | FRDM==""		// drop observations with missing firm or product codes
xtset fpid yr

sort FRDM productcode yr 
xtset fpid yr
gen Lq = L.q							
merge m:1 FRDM yr using ./tempfiles/firmids_tobacco
keep if _merge==3
drop _merge

* Product unit codes
 
gen unit_s = "ton" if unit=="¶Ö"
replace unit_s = "millions" if unit=="ÍòÖ§"

tab unit_s

gen dunit_ton = unit=="¶Ö"
bys fpid: egen maxdunit_ton = max(dunit_ton)	// did firm ever use tons?

sort FRDM yr
brow if maxdunit_ton==1

* Transformation tons to cases

replace q = q*20 if maxdunit_ton==1		// 1 ton = 1000 kg = 1,000,000 cigarettes = 20 cases (with 1 gram per cigarette and 50,000 cigarettes per case in China)
  
sort unit FRDM yr

xtset fpid yr
corr L.q q_lag if yr~=2004 //if yr>2003		// compare lagged units to units in previous year file. Align well except in 2004
corr L.q q_lag  							// there is a problem in 2004: unit definition changes. Solved this using 'ratio' variable below

xtset fpid yr
sum q if unit == "¶Ö" & yr>2003

rename (q q_lag) (q_old q_lag_old)

gen q = q_old if yr<2004
gen q_lag = q_lag_old if yr<2004
replace q = q_old if yr>=2004 & unit == "¶Ö"
replace q_lag = q_lag_old if yr>=2004 & unit == "¶Ö"		// same unit as used before 2004 (correlation q q_lag is 1)

bys yr: sum q

xtset fpid yr
gen ratio = q_lag_old/L.q_old if yr==2004	// this ratio tells us how the units are redefined in 2004

bys yr unit: sum ratio, d
bys fpid : egen maxratio=max(ratio)		 
 
replace q = q_old  if yr>=2004 & unit~="¶Ö"
replace q = q_old/maxratio if yr>=2004 & unit~="¶Ö"
gen cons=1
bys FRDM yr: egen nprod = sum(_cons)
bys yr: sum nprod						// number of reported products falls

xtset fpid yr 
corr q F.q_lag		// now, aligns pretty well: no more discontinuities in unit definitions

sort fpid yr 
brow fpid yr q q_old maxratio

collapse(sum) q q_old q_lag, by(FRDM yr)	// sum product-level quantities to the firm level

replace q = q_old if q==0 & q_old>0
 
save "./tempfiles/qf_tobacco", replace
bys yr: sum q
sort FRDM yr
 
restore
 
// Merge firm-level quantity data into ASIF dataset 
 
merge m:1 FRDM yr using "./tempfiles/qf_tobacco", nogen

xtset fid yr
replace q = F.q_lag if yr==1999	// impute quantities for 1999 by observed lagged quantities in 2000. excludes firm that exited in 1999.

gen p = rev/q
gen pm = m/q
bys yr: sum p pm , d
 
*** Currencies

label var p "Unit price"
gen usd_rmb = 1/8.31			// currency unit = 1000 RMB (in 1998) = 120 USD (in 1998)	 

/* 4. English translations */

** product names

tab hs02_4, gen(dhs)

merge m:1 FRDM yr using ./data/translations/prodnames, force
drop if _merge==2
drop _merge

** English firm names

preserve
import delimited using ./data/translations/mergers, clear delim(";")	// firm name translations (using google translate)
duplicates tag frdm, gen(dup)
drop if dup>0
drop dup
rename (frdm v3)(FRDM firmname_en)
keep FRDM firmname_en
save ./tempfiles/firmname_en, replace
restore

merge m:1 FRDM using ./tempfiles/firmname_en
drop _merge

bys firmname_en: egen firm_startyr = min(yr) 
bys firmname_en: egen firm_endyr = max(yr) 

** Province names

forvalues n = 1/6 {
gen zip`n'=substr(zip,1,`n')
encode zip`n',gen(zip`n'id)
}

preserve
import delimited using  ./data/translations/provincenames_EN, clear	// english province names
tostring zip2, replace
replace zip2="01" if zip2=="1"
replace zip2="02" if zip2=="2"
replace zip2="03" if zip2=="3"
replace zip2="04" if zip2=="4"
replace zip2="05" if zip2=="5"
replace zip2="07" if zip2=="7"
save ./tempfiles/provincenames_EN, replace
restore

merge m:1 zip2 using ./tempfiles/provincenames_EN //, nogen
drop if _merge==2
drop _merge
encode province_name, gen(province_id)	

** Ownership types

destring type, gen(ownership)
recode ownership 110 141 143 151=1 120 130 142 149=2 171 172 173 174 190=3 210 220 230 240=4 310 320 330 340=5 	// ownership classification using Brandt et al. (2012)
gen typeid=ownership
recode typeid 159=6 160=7
/* 1= SOE, 2= Collective, 3 = Private, 4 = Foreign, 5 = Hong Kong Macao, 6 = Joint stock, 7 = Stock shareholding*/

tab typeid, gen(typeid)	

bys province_name yr: egen revall=sum(rev)	// total manufacturing revenue  (province)
bys province_name yr: egen empall=sum(emp)	// total manufacturing employment  (province)

/* 5. Geographical coordinates */

preserve
import delimited using ./data/coordinates/county_coords, delim(";") stringcols(1) clear		// county coordinates
split county_coord, parse(",")
rename (county_coord1 county_coord2) (_y _x)
foreach var of varlist _y _x {
destring `var', replace
}
tostring zip4, replace
save ./tempfiles/county_coords, replace
restore

merge m:1 zip4 using ./tempfiles/county_coords	// give coordinates to firms based on the county (zip4 postal code)
drop _merge


/* 6. Product characteristics */
 
** Match firms to brands
preserve
import delimited using ./data/productchar/data_brandfirm, delim(";") clear varnames(1)		// firm - brand matches
drop if firmbrandname=="" | firmbrandname==" "
save ./tempfiles/data_brandfirm, replace
restore

** Import product characteristics

preserve
import delimited using ./data/productchar/data_characteristics, delim(";") clear		// cigarette brand characteristics
recast str106 brandname, force
rename (tobaccoweightmg filterdens roddens paperperm ventil) (char_weight char_filter char_rod char_paper char_ventil)
merge m:1 brandname using ./data/productchar/data_brandfirm		
keep if _merge==3
drop _merge
collapse char* , by(firmbrandname)
save ./tempfiles/data_characteristics_firm, replace		// characteristics at brand level
restore

** Firm names
preserve
import delimited using ./data/productchar/data_concord_firm, delim(";") clear		// cigarette brand characteristics
collapse firm_startyr , by(firmname_en firmbrandname)
drop firm_startyr
save ./tempfiles/data_concord_firm, replace
restore

merge m:1 firmname_en using ./tempfiles/data_concord_firm		// match firm names to english translations
drop if _merge==2
drop _merge

merge m:1 firmbrandname using ./tempfiles/data_characteristics_firm			// match avg product characteristics to each firm
drop if _merge==2
drop _merge
  
gen dchar = char_weight~=.
gen lchar_weight = log(char_weight)

/* 7.  Chinese census of population (2000)*/

save ./tempfiles/china_data_temp, replace
   
** A0111 - population and number of households

foreach n in "11" "12" "13" "14" "15" "21" "22" "23" "31" "32" "33" "34" "35" "36" "37" "41" "42" "43" "44" "45" "46" "50" "51" "52" "53" "54" "61" "62" "63" "64" "65"	{		// 31 province codes
	local f = "A0111" 	
	import delimited using ./data/population_census/population_census2000/censusfiles/J`n'`f'.tab, clear varnames(1)
	rename (v1 v2 v3) (county township nh)		
	drop v*
		foreach var of varlist nh{
		destring `var', replace
		}
 	bys county township:  gen dup = cond(_N==1,0,_n)
 	drop if dup>0
	gen provincecode = `n'
 	keep if township=="Total"
	collapse(sum) nh, by(county provincecode)
	save ./tempfiles/temp`n'`f', replace
}
  

** A0105 Urban-rural population

foreach n in "11" "12" "13" "14" "15" "21" "22" "23" "31" "32" "33" "34" "35" "36" "37" "41" "42" "43" "44" "45" "46" "50" "51" "52" "53" "54" "61" "62" "63" "64" "65"	{		// 31 province codes
	local f = "A0105" 	// census file type
	import delimited using ./data/population_census/population_census2000/censusfiles/J`n'`f'.tab, clear varnames(1)
	rename (v1-v11) (county township pop popm popf popag popagm popagf popur popurm popurf)		// these are in 'varnames.xls'
	gen provincecode = `n'
	drop v*
		foreach var of varlist pop*{
		destring `var', replace
		}
 	quietly bys county township:  gen dup = cond(_N==1,0,_n)
 	drop if dup>0
 drop if township=="Total"		 
	collapse(sum) pop popm popf popag popagm popagf popur popurm popurf, by(county provincecode)
	label var popag "agricultural population"
	label var popagm "agricultural population, male"
	label var popagf "agricultural population, female"
	label var popur "non-agricultural population"
	label var popurm "non-agricultural population, male"
	label var popurf "non-agricultural population, female"
	save ./tempfiles/temp`n'`f', replace
}
  
** A0109 Population of 15 years and older

foreach n in "11" "12" "13" "14" "15" "21" "22" "23" "31" "32" "33" "34" "35" "36" "37" "41" "42" "43" "44" "45" "46" "50" "51" "52" "53" "54" "61" "62" "63" "64" "65"	{		// 31 province codes
	local f = "A0109" 	// census file type
	import delimited using ./data/population_census/population_census2000/censusfiles/J`n'`f'.tab, clear varnames(1)
	keep v1 v2 v3 v9 
	rename (v1 v2 v3 ) (county township popadult)		
	gen provincecode = `n'
		foreach var of varlist pop*{
		destring `var', replace
		}
	quietly bys county township:  gen dup = cond(_N==1,0,_n)
	drop if dup>0
 drop if township=="Total"		 
	collapse(sum) pop*, by(county provincecode)
	label var popadult "Adult population"
	save ./tempfiles/temp`n'`f', replace
}

** L0105 Employed and unemployed people (sample)

foreach n in "11" "12" "13" "14" "15" "21" "22" "23" "31" "32" "33" "34" "35" "36" "37" "41" "42" "43" "44" "45" "46" "50" "51" "52" "53" "54" "61" "62" "63" "64" "65"	{		// 31 province codes
	local f = "L0105" 	// census file type
	import delimited using ./data/population_census/population_census2000/censusfiles/J`n'`f'.tab, clear varnames(1)
	keep v1 v2 v3 v6 v9 
	rename (v1 v2 v3 v6 v9) (county township pop_adult_sample pop_emp_sample pop_unemp_sample)		
	gen provincecode = `n'
		foreach var of varlist pop*{
		destring `var', replace
		}
 	quietly bys county township:  gen dup = cond(_N==1,0,_n)
 	drop if dup>0
 drop if township=="Total"		 
	collapse(sum) pop*, by(county provincecode)
	label var pop_emp "Employed population (sample)"
	label var pop_unemp "Unemployed population (sample)"
	label var pop_adult "Unemployed population (sample)"
	save ./tempfiles/temp`n'`f', replace
}

** Match all census files

use ./tempfiles/temp11A0111, clear

foreach n in "12" "13" "14" "15" "21" "22" "23" "31" "32" "33" "34" "35" "36" "37" "41" "42" "43" "44" "45" "46" "50" "51" "52" "53" "54" "61" "62" "63" "64" "65" {
merge m:1 county provincecode using ./tempfiles/temp`n'A0111, nogen update
}

foreach n in "12" "13" "14" "15" "21" "22" "23" "31" "32" "33" "34" "35" "36" "37" "41" "42" "43" "44" "45" "46" "50" "51" "52" "53" "54" "61" "62" "63" "64" "65" {
foreach f in     "A0105"   "A0109" "L0105"  {
merge m:1 county provincecode using ./tempfiles/temp`n'`f', update nogen
}
}
drop if county==""
  
** Calculate share of working population that is active (working or looking for work)

gen pct_lab = (pop_emp_sample + pop_unemp_sample)/(pop_adult_sample)
sum pct_lab
gen pop_lab = pct_lab*popadult		// labor force is percentage of 15+ that is active times adult population 
  
label var county "county name"
label var provincecode "province code"
label var pop "total population"
 
* Province codes

preserve
import delimited using ./data/population_census/population_census2000/provincecodes, clear delim(";")
label var province "province name"
label var provincecode "province code"
save ./tempfiles/provincecodes, replace
restore

merge m:1 provincecode using ./tempfiles/provincecodes, nogen
order provincecode, before(county)
order province, before(provincecode)
  

** Match county names to 6 digit dq codes

preserve
import delimited using ./data/population_census/population_census2000/countycodes, clear delim(";")
duplicates tag county province, gen(dup)
drop if dup>0
drop dup
save ./tempfiles/countycodes, replace
restore

* drop space at end of county name (necessary for string matching)
replace county = substr(county, 1, length(county)-1)
 
 
merge m:1 province county using ./tempfiles/countycodes
keep if _merge == 3
drop _merge

sum pop_lab
 
label var dq6 "dq code, 6 digit"

 tostring dq6, replace
  
save ./tempfiles/censusdata_6digit, replace
  
* Load census data into ASIF dataset

use ./tempfiles/china_data_temp, clear 
  
* dq code
forvalues n = 1/6 {
gen dq`n' = substr(dq,1,`n')
encode dq`n', gen(dq`n'id)
bys dq`n'id yr: egen ndq`n'=sum(open)
tab ndq`n', gen(ndq`n'_)
}

merge m:1 dq6 using ./tempfiles/censusdata_6digit 
drop if _merge==2
drop _merge

* rural urban pop

gen pctagr = popag/pop
  
gen pctlab = pop_lab/pop
sum pctlab, d

drop dq2* dq3* dq4* dq5* dq6*
** Location codes
forvalues m = 2/6 {
gen dq`m' = substr(dq,1,`m')
destring dq`m', gen(dq`m'id)
}
sum pop*
gen urate = pop_unemp/(pop_unemp+pop_emp)
gen erate = 1-urate

foreach var in "ag" {
gen pct`var' = pop`var'/pop
gen lpct`var' = log(pct`var')
}

gen provtob1 = province_name == "Yunnan" 
gen provtob2 = province_name == "Guizhou" 
gen provtob3 = province_name == "Henan" 
gen provtob=provtob1+provtob2+provtob3

gen lurate = log(urate)

*** Ownership data

gen eq_tot = e_state+e_col+e_leg + e_ind+e_HMT+e_for
bys yr: egen eq_totyr = sum(eq_tot)

foreach var of varlist e_*{
replace `var' = . if `var'<0
gen s`var' = `var'/eq_tot
bys yr: egen `var'yr = sum(`var')
gen pct`var'yr = `var'yr/eq_totyr
}

sum pcte_*
twoway connect pcte_state yr //if yr<2007

sum se*

label var se_state "Equity share held by the state"
label var se_legal "Equity share held by the legal person"


/* 8. Cleaning 
------------------------------------------*/

*** Data cleaning

di _N
keep if yr>=1999 & yr<2007		// only have quantity data between 1999 and 2006
drop if m<0						// drop obs with negative material input
di _N

foreach var of varlist q pm {				// remove outliers for output and leaf price
egen `var'01 = pctile(`var'), p(01)
egen `var'99 = pctile(`var'), p(99)
replace `var' = . if `var'<`var'01 | `var'>`var'99
}

*** Summary statistics 

bys yr: egen profyr = sum(prof)
bys yr: egen revyr = sum(rev)
 
foreach var of varlist  pm p{
gen `var'_usd = `var'*usd_rmb  		// revenues in 1000s, quantities not
}

foreach var of varlist p pm p_usd pm_usd {
gen `var'_case = `var'  *1000	// revenues in 1000, quantities not
gen `var'_stick = `var'_case/50000		// 50,000 sticks per case
gen `var'_pack = `var'_stick*20		// 20 sticks per pack
}

sum p_usd_pack  pm_usd_pack
 
/* 9. Consolidation treatment effects: define treatment and control group
------------------------------------------------------------------------*/

** Treatment dummy: being in market with 1 or more firms producing less than 100M cigarettes in 2001

forvalues n = 1(2)3 {
gen under`n'00K = q<=`n'00000		// annual production lower than `n'00 000 cigarettes
replace under`n'00K=. if q==.
gen above`n'00K = 1- under`n'00K		// annual production higher than `n'00 000 cigarettes
}

forvalues y = 1999(1)2006{
gen d`y' = yr==`y'				// year dummies
}	

gen post02=yr>=2002		// post 2002 dummy
gen post03=yr>=2003		// post 2003 dummy
 
gen under100K_2001 = under100K*d2001		// dummy for producing less than 100M cigarette cases in 2001 (before the policy started)

forvalues m = 2/6 {					
bys dq`m'id yr: egen nunder100K_dq`m'=sum(under100K_2001)	// number of firms producing less than 100K cigarette cases in 2001 in m-digit location (county is 6 digit)
bys dq`m'id: egen maxnunder100K_dq`m' = max(nunder100K_dq`m')	// get this number for every market throughout entire time period

gen treat_dq`m' = maxnunder100K_dq`m'>0			// dummy for whether there was at least one firm producing less than 100K cases in 2001.
replace treat_dq`m' = . if 	maxnunder100K_dq`m'==.	// treatment group: more than one firm under threshold before 2002
gen treat02_dq`m' = treat_dq`m'*post02			// treatment group * treatment period
gen treat03_dq`m' = treat_dq`m'*post03			// treatment group * treatment period
}

// same for having firms with output below 300K cases in 2001

gen under300K_2001 = under300K*d2001
forvalues m = 2/6 {					// various market sizes
bys dq`m'id yr: egen nunder300K_dq`m'=sum(under300K_2001)
bys dq`m'id: egen maxnunder300K_dq`m' = max(nunder300K_dq`m')

gen nmerger_dq`m' = maxnunder300K_dq`m'

gen merger_dq`m' = nmerger_dq`m'>0	
replace merger_dq`m' = . if 	merger_dq`m'==.	// treatment group: more than one firm under threshold before 2002
gen merger02_dq`m' = merger_dq`m'*post02			// treatment group * treatment period
gen merger03_dq`m' = merger_dq`m'*post03			// treatment group * treatment period

}

foreach var of varlist q p pm {				
gen l`var' = log(`var')				// take logs
}

/* 10. Quality data
------------------------------------------------------------------------*/

preserve
set more off
use ./data/quality/NBS_Tobacco_qdata_year_panel, clear		// product-level   data with different qualities 
  
keep if product_code=="03338" | product_code=="03345" | product_code=="03352"| product_code=="03369"
gen yr = year
bys yr product_code: egen q_type = sum(q)
bys yr: egen qyr = sum(q)

gen qual = 1 if product_code=="03338"
replace qual = 2 if  product_code=="03345"
replace qual = 3 if  product_code=="03352"
replace qual = 4 if  product_code=="03369"
gen sq_type = q_type/qyr*qual

twoway connect sq_type yr if qual==1 ///
|| connect sq_type yr if qual==2 ///
|| connect sq_type yr if qual==3 ///
|| connect sq_type yr if qual==4 

bys FRDM yr qual: egen qqual = sum(q)
bys FRDM yr  : egen qf = sum(q)
gen sqqual = qqual/qf*qual

collapse qual sqqual, by(FRDM yr)
encode FRDM, gen(fid)
xtset fid yr
 reg qual i.fid 
 reg qual L.qual  
 sum sqqual
 
save ./data/quality/data_quality, replace
restore
  
* Compile tax and subsidy data (from ASIF)

preserve
clear
set more off
* Tax data

*1999

use ./data/nbsdata/1999, clear

for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM

gen yr = 1999
		
for any 产品销售税金及附加: /// 
capture rename X sales_tax
		
for any 税金: /// 
capture rename X other_tax

for any 应交所得税: /// 
capture rename X income_tax

for any  本年进项税额: /// 
capture rename X input_tax 

for any 	补贴收入: ///
capture rename X subsidy

collapse(sum) *tax subsidy, by(FRDM yr)

save ./data/nbsdata/tax/tax1999, replace


*2000
use ./data/nbsdata/2000, clear

for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM

gen yr = 2000
		
for any 		销售税附加		: /// 
capture rename X sales_tax
		
for any 税金	: /// 
capture rename X other_tax

for any 就交所得税	: /// 
capture rename X income_tax

for any  	本年进项税	: /// 
capture rename X input_tax 

for any  中间投入合	税金（加）		: /// 
capture rename X input_tax2 


for any 	补贴收入: ///
capture rename X subsidy

collapse(sum) *tax subsidy, by(FRDM yr)

save ./data/nbsdata/tax/tax2000, replace


*2001
use ./data/nbsdata/2001, clear

for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM

gen yr = 2001
		
for any 		销项税额　		: /// 
capture rename X sales_tax
		
for any 税金	: /// 
capture rename X other_tax

for any 	 应交所得税		: /// 
capture rename X income_tax

for any  	进项税额			: /// 
capture rename X input_tax 

for any  	中间投入计			: /// 
capture rename X input_tax2 

for any 	补贴收入: ///
capture rename X subsidy


collapse(sum) *tax subsidy, by(FRDM yr)

save ./data/nbsdata/tax/tax2001, replace

*2002
use ./data/nbsdata/2002, clear

for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM
 
gen yr = 2002
 		
for any 		本年销项税 : /// 
capture rename X sales_tax
		
for any 	税金	: /// 
capture rename X other_tax

for any 	 	应交所得税	: /// 
capture rename X income_tax

for any  	进项税额			: /// 
capture rename X input_tax 

for any  		中间投入计				: /// 
capture rename X input_tax2 

for any 	补帖收入: ///
capture rename X subsidy


collapse(sum) *tax subsidy, by(FRDM yr)

save ./data/nbsdata/tax/tax2002, replace


*2003
use ./data/nbsdata/2003, clear

for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM

gen yr = 2003
		
for any 		销项税额		: /// 
capture rename X sales_tax
		
for any 	税金	: /// 
capture rename X other_tax

for any 	 应交所得税		: /// 
capture rename X income_tax

for any  	进项税额	: /// 
capture rename X input_tax 

for any  		中间投入计				: /// 
capture rename X input_tax2 

for any  		中间投入计				: /// 
capture rename X input_tax2 

for any 	补帖收入: ///
capture rename X 

collapse(sum) *tax, by(FRDM yr)

save ./data/nbsdata/tax/tax2003, replace


*2005
use ./data/nbsdata/2005, clear
for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM
 
gen yr = 2005
		
for any 	F355	: /// 
capture rename X sales_tax
		
for any 	税金	: /// 
capture rename X other_tax

for any 	 F345: /// 
capture rename X income_tax

for any  F354		: /// 
capture rename X input_tax 

for any F343		: /// 
capture rename X subsidy 

collapse(sum) subsidy *tax, by(FRDM yr)

save ./data/nbsdata/tax/tax2005, replace


*2006
use ./data/nbsdata/2006, clear

for any frdm entitycode 法人代码 法人单位代码 组织机构代码 id B056: ///   
capture rename X FRDM
 
gen yr = 2006
		
for any 		F355	: /// 
capture rename X sales_tax
		
for any 	税金	: /// 
capture rename X other_tax

for any 	F345: /// 
capture rename X income_tax

for any  	F354		: /// 
capture rename X input_tax 

for any F343		: /// 
capture rename X subsidy 


collapse(sum) *tax subsidy, by(FRDM yr)

save ./data/nbsdata/tax/tax2006, replace

restore
 
 
*** Merge tax and subsidy data (from ASIF)
 
forvalues m = 1999/2003 {
merge m:1 FRDM yr using ./data/nbsdata/tax/tax`m', update
drop if _merge==2
drop _merge
}
forvalues m = 2005/2006 {
merge m:1 FRDM yr using   ./data/nbsdata/tax/tax`m', update
drop if _merge==2
drop _merge
}

gen ssales_tax = sales_tax/rev
sum ssales_tax, d

gen sinput_tax= input_tax/rev
sum sinput_tax, d

gen lssales_tax = log(sales_tax)

gen ssub = subsidy/rev
replace ssub = . if rev==0

gen dsub = sub>0
replace dsub = . if sub==.


/* 11. Product names: translations
------------------------------------------------------------------------*/

** English translations for product names

preserve
import excel using ./data/product_names/prodnames.xlsx, clear firstrow			// english translations
quietly bys prod:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
rename prod prod1
gen dcigarette=prodname_en=="Cigarette" |prodname_en=="Cigarette cigarette"| prodname_en=="Cigarette company"|prodname_en=="Cigarette industry"|prodname_en=="Cigarette management"    |prodname_en=="Cigarette manufacturing" | prodname_en=="Cigarette production"|prodname_en=="Cigarette production and processing"  | prodname_en=="Cigarette production and sales"|prodname_en=="Cigarette production, sales"|prodname_en=="Cigarette products"|prodname_en=="Cigarette products industry"|prodname_en=="Cigarette sales"|prodname_en=="Cigarette stick"|prodname_en=="Cigarette tow"|prodname_en=="Manufacture of cigarettes"|prodname_en=="Moon rabbit series cigarette"|prodname_en=="Production of cigarettes"|prodname_en=="Three types of cigarettes"|prodname_en=="Various types of cigarettes"|prodname_en=="Yunhe Cigarette"|prodname_en=="cigarette"
save ./data/product_names/prodnames_en, replace
restore

* This do-file links the product codes in the data to English product names

preserve 

forvalues y = 1998/1999 {

use ./data/nbsdata/`y', clear
keep if 行业类别=="1610" | 行业类别=="1620" | 行业类别=="1690"				// "行业类别" = "product code"
keep 行业类别 产品1 产品2 产品3	法人代码		// product code, product 1, product 2, product 3, corporate id
rename (行业类别 产品1 产品2 产品3	法人代码) (productid prod1 prod2 prod3 FRDM)
gen yr=`y'
save "./data/product_names/products`y'", replace
}

forvalues y = 2000/2000 {
use ./data/nbsdata/`y', clear
keep if 行业类别=="1610" | 行业类别=="1620" | 行业类别=="1690"				// "行业类别" = "product code"
keep 行业类别 主要产品1 主要产品2 主要产品3	法人代码						// product code, product 1, product 2, product 3, corporate id
rename (行业类别 主要产品1 主要产品2 主要产品3 法人代码) (productid prod1 prod2 prod3 FRDM)
gen yr=`y'
save "./data/product_names/products`y'", replace
}

forvalues y = 2001/2003 {
use ./data/nbsdata/`y', clear
keep if 行业类别=="1610" | 行业类别=="1620" | 行业类别=="1690"				// "行业类别" = "product code"
keep 行业类别 产品1 产品2 产品3	法人代码		// product code, product 1, product 2, product 3, corporate id
rename (行业类别 产品1 产品2 产品3	法人代码) (productid prod1 prod2 prod3 FRDM)
gen yr=`y'
save "./data/product_names/products`y'", replace

}

forvalues y = 2004/2006 {
use ./data/nbsdata/`y', clear
keep if B07=="1610" | B07=="1620" | B07=="1690"				// "行业类别" = "product code"
keep  B07 B071 B072 B073 FRDM	// product code, product 1, product 2, product 3, corporate id
rename (B07 B071 B072 B073 FRDM) (productid prod1 prod2 prod3 FRDM)
quietly bys FRDM:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
gen yr=`y'
save "./data/product_names/products`y'", replace
}

forvalues y = 2007/2007 {
use ./data/nbsdata/`y', clear
keep if 行业代码=="1610" | 行业代码=="1620" | 行业代码=="1690"				// "行业类别" = "product code"
keep 行业代码 主要业务活动（或主要产品）1 主要业务活动（或主要产品）2 主要业务活动（或主要产品）3	法人单位代码		// product code, product 1, product 2, product 3, corporate id
rename (行业代码 主要业务活动（或主要产品）1 主要业务活动（或主要产品）2 主要业务活动（或主要产品）3	法人单位代码	) (productid prod1 prod2 prod3 FRDM)
quietly bys FRDM:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
gen yr=`y'
save "./data/product_names/products`y'", replace
}

use "./data/product_names/products1998", clear
forvalues y = 1999/2007 {
merge m:1 yr FRDM using  "./data/product_names/products`y'", replace update nogen
}

merge m:1 prod1 using ./data/product_names/prodnames_en
drop if _merge==2
drop _merge

save ./data/product_names/prodnames, replace

restore


/* 12. Weather data 
 ------------------------------------------------------------------------*/

/*   imports raw weather data and write it into file 'weatherdata.dta'*/

preserve
import delimited using ./data/climate/station_names, delim(";") varnames(1) clear
drop if station_id==.
quietly bys station_id:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
save ./data/climate/station_names, replace
restore

// Source: "China Earth International Exchange Station climate data annual value data set"
preserve 
forvalues n = 1/29 {
import delimited using ./data/climate/climate`n'.txt, delim(" ") clear
rename (v01301 v04001 v12012 v12011 v12012_701 v12011_701 v14032 v13032 v13052) (station_id yr mintemp maxtemp avgmintemp avgmaxtemp sunshine evaporation rain) 
keep station_id yr mintemp maxtemp avgmintemp avgmaxtemp sunshine evaporation rain
save ./data/climate/climate`n', replace
}

use ./data/climate/climate1, clear

forvalues n = 2/29 {
merge m:1 station_id yr using ./data/climate/climate`n', nogen
}
 
merge m:1 station_id using ./data/climate/station_names
drop _merge

egen station_num = group(station_id)

foreach var of varlist yr mintemp maxtemp avgmintemp avgmaxtemp sunshine evaporation rain {
replace `var'=. if `var'==999999
}

gen _xs  = substr(station_lat, 1,5)
gen _ys  = substr(station_long, 1,4)

sort _xs

save ./data/climate/weatherdata, replace
restore

* Match counties to closest weather station

 
preserve 
do ./main/china_tobacco_weatherstation_matching.do
restore 

* Merge Weather data into main dataset
 
merge m:1 zip4 using  ./data/climate/county_station_matching
drop if _merge==2
drop _merge

merge m:1 station_num yr using ./data/climate/weatherdata 
drop if _merge==2
drop _merge
 
  

save ./data/china_tobacco_data, replace
