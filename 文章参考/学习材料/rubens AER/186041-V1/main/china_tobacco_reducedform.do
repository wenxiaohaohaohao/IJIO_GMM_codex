/*	Market Structure, Oligopsony Power, and Productivity
			(Michael Rubens, UCLA)

			- REDUCED FORM EVIDENCE -
============================================================================*/

cd "$station"

set more off
 
* Import dataset 

use ./data/china_tobacco_data, clear		// dataset created in china_tobacco_data.do 
xtset fid yr

gen alphaM = m/rev		// revenue share of materials
gen alphaL = w/rev		// revenue share of labor
gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.	// dummy indicating that variables needed to estimate main model are observed.

** Dataset description

* how many firms per county
preserve
drop if emp==0
gen nf = emp~=.
collapse(sum) nf, by(dq6id yr)		
bys yr: sum nf, d
restore
  
* how many firms produce below 100K cigarettes/year  
preserve
keep if under100K~=.		
keep if yr==2002
tab under100K				// 50% of firms
collapse(sum) rev, by(under100K)
egen agrev = sum(rev)
gen srev = rev/agrev
bys under100K: sum srev 	//7% of revenue
restore
      
* market share for single vs. multiproduct firms  
sum prod*
gen singleprod  = prod2==""		
tab singleprod // 88% of firms

preserve
collapse(sum) rev, by(singleprod)
egen trev = sum(rev)
gen srev = rev/ trev
bys singleprod: sum srev	// 91% of sales
restore

* number of firms per county
preserve
keep if q>0 & q~=. & treat_dq6==1
gen nf = 1
collapse(sum) nf, by(dq6id yr)	
bys yr: tab nf
restore

* number of firms per year
preserve
gen nf = 1
collapse(sum) nf, by(yr)
bys yr: sum nf
restore
 
* number of observations for which all variables are observed
 
preserve
keep if dumobs==1
xtdes
di _N			// N=1,132
restore

* share of revenue covered by selected sample

preserve
replace dumobs = 0 if dumobs~=1
collapse(sum) rev, by(dumobs)
bys dumobs: sum rev
egen revtot=sum(rev)
gen srev_obs = rev/revtot
bys dumobs: sum srev_obs	// selected sample covers 78% of revenue
restore
 
* Summary statistics

gen popM_dq6 = pop/1000000
gen qK = q/1000
foreach var of varlist rev prof w m k {
gen `var'M_usd = `var'/1000	*usd_rmb	// monetary variables are in 1,000 rmb
}
 
sum revM_usd qK p_usd_case profM wM_usd emp  mM_usd kM_usd dexp pctexp popM_dq6 char_weight char_filter if dumobs==1

foreach var of varlist revM qK p_usd_case profM wM emp  mM kM dexp pctexp popM_dq6 char_weight char_filter {
egen av`var' = mean(`var') if q~=. & p~=. & m~=. & m>0 & k~=.
egen sd`var' = sd(`var') if q~=. & p~=. & m~=. & m>0 & k~=.
}

estpost su  revM_usd   qK  p_usd_case  profM  wM   mM  kM   emp  dexp  pctexp  popM_dq6  char_weight  char_filter if dumobs==1	// summary statistics
est store sumstat 
  
* Revenue shares 
 
foreach var of varlist m w {
bys yr: egen `var'yr = sum(`var')
gen ag`var'share = `var'yr/revyr
}
label var agmshare "Intermediate inputs"
label var agwshare "Labor"
sort yr
twoway connect agmshare agwshare yr , lwidth(thick thick) mfcolor(white white) graphregion(color(white)) lcolor(black black) lpattern(solid "_-_" ) msymbol(square diamond) msize(medlarge medlarge) mcolor(black black) ytitle("Expenditure/Revenue",size(medlarge)) xlabel(1999(1)2006) ylabel(, angle(0) ) //title("Revenue shares, weighted average")
graph export "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/figures/Figure2b.pdf", replace

preserve
gen mrev = m/rev
gen wrev = w/rev 
egen m1 = pctile(mrev), p(01)
egen m99 = pctile(mrev), p(99)
drop if mrev<m1 | mrev>m99
egen w1 = pctile(wrev), p(01)
egen w99 = pctile(wrev), p(99)
drop if wrev<w1 | wrev>w99
bys yr: egen avmshare=mean(mrev)
bys yr: egen avwshare=mean(wrev)
    
twoway line avmshare avwshare yr , lwidth(thick thick)  graphregion(color(white)) lcolor(black black) lpattern(solid "_-_" ) ytitle("Expenditure/Revenue",size(medlarge)) xlabel(1999(1)2006) ylabel(, angle(0) ) //title("Revenue shares, weighted average")
restore 
  
* Number of firms above and below 100K cases
 
bys yr: egen nunder100K=sum(under100K)		
bys yr: egen nabove100K=sum(above100K)
bys yr: sum nunder100K nabove100K
 
graph bar nunder100K nabove100K if yr>1998 & yr<2007 , over(yr) bar(2,  fintensity(50) fcolor(black) lcolor(black) ) bar(1,  fintensity(0) lcolor(black) ) legend(label(1 "Q<100K cases") label( 2 "Q>100K cases")) ytitle("# Firms", size(medlarge))  graphregion(color(white)) ylabel(, angle(0) )
graph export "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/figures/Figure2a.pdf", replace
   
* 'Special' survivors 

preserve
gen special = under100K == 1 & yr==2006
keep if special==1
keep if q~=0
tab typeid	// 10 firms survived despite Q<100K. Only 3 SOEs, though.
restore

// # Firms per market

preserve
set more off
local m = 6
collapse(sum) open, by(dq`m'id treat_dq`m' yr)
rename open nf_dq`m'
xtset dq`m'id yr
xtdes
sum nf_dq6 , d
tab nf_dq6 
restore
  
preserve
local m = 6
collapse(sum) open, by(dq`m'id yr)
sum open	//1.24 firms per prefecture on average
gen nf1 = open==1 	// 1 firm in county
tab nf1				//80\% monopsonistic counties
restore    
 
  
/* Prices and market structure */

forvalues n = 2(2)6 {

preserve
 
bys dq`n'id yr: egen nf_dq`n'=sum(open)
keep if q ~=. & m ~=. 
drop pm
gen pm = m/q
collapse (mean) pm nf_dq`n', by(dq`n'id yr)
gen lpm = log(pm)
tab nf_dq`n', gen(nf_dq`n'_)
reg lpm nf_dq`n'_1 nf_dq`n'_2  , r		// table A12
forvalues m = 1(1)2 {
local bnf`m'_dq`n' = _b[nf_dq`n'_`m']
local senf`m'_dq`n' = _se[nf_dq`n'_`m']
}
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_dq`n' = substr("`r2'",1,4)
drop r2 r2s
local N_dq`n' = e(N)
restore 
}
 

forvalues n = 2(2)6 {
forvalues m = 1(1)2 {
di `bnf`m'_dq`n''
di `senf`m'_dq`n''
}
}


// save to table
forvalues n = 2(2)6 {
forvalues m = 1(1)2 {
gen bnf`m' = `bnf`m'_dq`n''
}
estpost su bnf1 bnf2  
est store bnf_dq`n'
drop bnf1 bnf2  
}

forvalues n = 2(2)6 {
forvalues m = 1(1)2 {
gen bnf`m' = `senf`m'_dq`n''
}
estpost su bnf1 bnf2  
est store senf_dq`n' 
drop bnf1 bnf2  
}


*** Tables

** Table A3: summary statistics

 
 
label var  revM_usd "Revenue (million USD)"
label var  qK "Quantity (thousand cases)"
label var  p_usd_case "Price per case (USD)"
label var  profM "Profit (million USD)"
label var  mM_usd "Material expenditure (million USD)"
label var  emp  "Employees "
label var  wM_usd "Wage bill (million USD)"
label var  kM_usd "Capital stock (million USD)"
label var  dexp "Export dummy"
label var  pctexp "Export share of revenue"
label var  popM_dq6  "County population (millions)"
label var  char_weight "Leaf content per cigarette (mg)"
label var  char_filter "Filter density (mg/ml)"
 
esttab sumstat  using "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/tables/tableA3.tex", replace ///
mtitle("" "" "" ) cells( " mean(fmt(2 ))  sd(fmt(2))   count(fmt(0 ))" )   prehead( \\  \hline \vspace{-1em} )  label booktabs nonum noobs collabels("Mean" "S.D.""Obs.") gaps f   ///
prefoot( &&& \vspace{-0.5em}\\ \hline) posthead( \hline &&&\\    )    

** Table A12: market structure and leaf prices

foreach var in "bnf1" "bnf2" "bnf3" {
gen `var' = 1
}

label var bnf1 "1 firm"
label var bnf2 "2 firms"
label var bnf3 "3 firms"

esttab bnf_dq2 senf_dq2 bnf_dq4 senf_dq4 bnf_dq6 senf_dq6 using "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/tables/tableA12.tex", replace   ///
prehead(  \textit{}& \multicolumn{6}{c}{log(Leaf price)} \\ \cline{4-5} & \multicolumn{2}{c}{Province}&  \multicolumn{2}{c}{Prefecture}  &  \multicolumn{2}{c}{County}   \\ \cline{2-7})   ///
mtitle("Est." "S.E." "Est." "S.E." "Est." "S.E.") cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f  ///
prefoot(\vspace{-0.75em} \\ \vspace{0.25em}   R-squared & \multicolumn{2}{c}{`r2_dq2'}& \multicolumn{2}{c}{`r2_dq4'} & \multicolumn{2}{c}{`r2_dq6'} \vspace{0.25em}  \\ ///
Observations & \multicolumn{2}{c}{`N_dq2'}& \multicolumn{2}{c}{`N_dq4'} & \multicolumn{2}{c}{`N_dq6'} \vspace{0.5em} \\ \hline  )  posthead( \hline &&&\\   ) 
 
 
/* Treatment & control group sizes */

preserve
drop if q==.
drop if yr>=2002
foreach var of varlist rev emp open q {
bys yr: egen `var'_yr = sum(`var')
forvalues m = 2(2)6 {
gen `var'_treat_dq`m'=`var'*treat_dq`m'
bys yr: egen `var'_treat_dq`m'_yr = sum(`var'_treat_dq`m')
gen s`var'_treat_dq`m' = `var'_treat_dq`m'_yr/`var'_yr
}
}
sum sopen* if yr==2001
sum srev* if yr==2001
sum sq* if yr==2001
restore
  
   
/* Share of output and revenue observed */

gen revobs = rev*dumobs
gen qobs = q*dumobs
 
egen revobstot = sum(revobs) 
egen qobstot = sum(qobs)
egen revtot = sum(rev)
egen qtot = sum(q)
gen srevobs = revobstot/revtot
gen sqobs = qobstot/qtot

sum sqobs srevobs	// observe 95\% of output and 80\% of revenue

/* Bunching */ 

twoway kdensity q if yr==1999 & q<400000 , lwidth(thick) legend(label(1 "1999")) lcolor(black) lpattern(solid) ||  kdensity q if yr==2000 & q<400000  , lcolor(black) lwidth(thick)   legend(label(2 "2000")) lpattern(longdash) ||   kdensity q if yr==2001 & q<400000 /*& q<300000 & q>50000*/,  lcolor(black) lpattern(shortdash) legend(label(3 "2001")) lwidth(thick) ///
/*||   kdensity q if yr==2002 & q<300000 & q>50000,  lcolor(black) lpattern("_-.") legend(label(4 "2002")) lwidth(thick)*/ graphregion(color(white)) xline(100000 300000, lwidth(thick)) ytitle("Probability density") xtitle("Annual output in cases") ylabel(#3)
graph export "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/figures/FigureA1.pdf", replace

 
  

