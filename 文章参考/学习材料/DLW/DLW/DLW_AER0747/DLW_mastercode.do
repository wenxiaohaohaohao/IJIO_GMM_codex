/* Markups and Firm-level Export Status -- American Economic Review: MASTER CODE
DE LOECKER JAN and WARZYNSKI FREDERIC June 2010

This master code file will first list the set of variables used in the analysis. Secondly we provide the
code to produce each table and result in the paper using STATA. There is nothing special about STATA except
in that we anticipate a larger set of user that are familiar with this package. 

*/

/*
Data: general structure (See pdf on how to get access to the data):

-Firm-level data with fid and year firm and year indicator in panel structure.
-See Data appendix in paper for exact measurement of variables. Note: all variables are deflated using industry
specific Price Indices (PPI, material PI, investment PI).
-Variables (lower case denotes logs): 
*output (Y, y), value_added (VA, va) labor (L, l), materials (M, m), capital (K, k), exportdummy (e), sales (S, s), exportsales (S_E, s_e), input prices (Z, z), year,
exit (1 if firm exits at year t), entry (1 if firm enters at year t), export_entry (1 if firm enter export market at t), 
export_exit (1 if firm exits export market at t), industry (dummy variable on NIC2 classification, see appendix), fid (firm indicator), wagebill, materialexpenditures.
*/

* Start by setting panel structure:
xtset fid year, yearly
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*
* Table 1: Table 1 Firm Turnover and Exporting in Slovenian Manufacturing
tabstat fid entry exit e, by(year) stat(N) format(%4.2f)
gen va_pw= value_added/L
tabstat va_pw, by(year) stat(mean) format(%4.2f)
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*
*Table 2: Estimated Markups

/* Step1: run DLW_procedure.do on data (by sector) and recover different markups under various specifications as listed in section V of the paper,
define markups as mu_1, ..., mu_6 for specifications I,..., VI, respectively.
*/
do DLW_procedure.do
*this file will produce markups for each specification of the production function, as well as an estimate of productivity (and the bootstrapped st. errors)
*Hall results: generate first difference and use average revenue shares for labor, material and capital.
* we provide the stantard CRS Hall-- approach here, robust to including RTS component.
gen dy=y-L.y
gen alpha_L=wagebill/S
gen alpha_M=materialexpenditures/S
gen x=alpha_L*l+alpha_M*m+(1-alpha_L-alpha_M)*k
gen dxhall=x-L.x
xi: reg dy dxhall i.year*i.industry
gen mu_hall=_b[dxhall]
gen dxhall_e=dxhall*e
xi: reg dy dxhall e dxhall_e i.year*i.industry
gen mu_hall_e=_b[dxhall_e]
/*Klette results: run Klette on each industry and collect markups:
 note: Klette uses Arellano-Bond (1991), we use a more efficient system GMM as in Arellano and Bover () and Blundell and Bond)
* we list alternative to using DPD in GAUSS by Arelano and Bond; and control for RTS parameter as well (see Klette 1995 for more details): 
*/
gen dl=l-L.l
gen dk=k-L.k
gen dm=m-L.m
gen dxklette=(alpha_L*(dl-dk)+alpha_M*(dm-dk))
gen dxklette_exp=dxklette*e
xtdpd dq (dxklette  dxklette_exp dk )  yr1996-yr2000, dgmmiv(l m k) lgmmiv(l m k) div(yr1996-yr2000) nocons hascons vce(gmm)
gen mu_klette =_b[dxklette_exp]

* Produce Table 2 using all estimates
tabstat mu_hall mu_klette mu_*, stat(median) format(%4.2f)
* note that the markups under hall and klette are simply point estimates from the respective regressions and Table 2 lists their corresponding standard errors.
* note we have already produced the Hall and Klette results under Table 2 and 3 above.
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*
* Table 3: Markups and Export Status I: Cross Section
* Table 4: |Markups and Export Status II: Export Entry Effect
* Results discussed in text of section V and VI: we only keep essential part of code for final results.

*The results in tables 3 and 4 get produced with following code:
gen lmu_1=ln(Markup_DLW1)
//1 standard cobb-douglas acf
gen lmu_2=ln(Markup_DLW2)
//2 1+ endog. process g(omega,e)
gen lmu_3=ln(Markup_DLW5)
//3 cd+exp inp+export process g(omega,e)
gen lmu_4=ln(Markup_DLWTL)
//4 translog (preferred specification throughout)
sort Id year
* create start variables
by Id: gen start=1 if exportdum[_n-1]==exportdum-1 
replace start=0 if start==.
label var start "1 at entry time
by Id: egen starter=sum(start)
*creat stop variables
by Id: gen stop=1 if exportdum[_n-1]==exportdum+1
replace stop=0 if stop==.
by Id: egen stopper=sum(stop)
gen switcher=1 if stopper>2 | starter>2
gen scale = year-"midsample" if neverexporters==1|alwaysexporters==1
"midsample" in our case was 1997, depends on length panel and can be varied.
replace scale=0 if start==1
sort Id year
by Id: replace scale =1 if exp_starter[_n-1]==1
by Id: replace scale =2 if exp_starter[_n-2]==1
by Id: replace scale =3 if exp_starter[_n-3]==1
by Id: replace scale =4 if exp_starter[_n-4]==1
by Id: replace scale =5 if exp_starter[_n-5]==1
by Id: replace scale =6 if exp_starter[_n-6]==1
by Id: replace scale =-1 if exp_starter[_n+1]==1
by Id: replace scale =-2 if exp_starter[_n+2]==1
by Id: replace scale =-3 if exp_starter[_n+3]==1
by Id: replace scale =-4 if exp_starter[_n+4]==1
by Id: replace scale =-5 if exp_starter[_n+5]==1
by Id: replace scale =-6 if exp_starter[_n+6]==1
replace scale=0 if stop==1
sort Id year
by Id: replace scale =1 if exp_quitter[_n-1]==1
by Id: replace scale =2 if exp_quitter[_n-2]==1
by Id: replace scale =3 if exp_quitter[_n-3]==1
by Id: replace scale =4 if exp_quitter[_n-4]==1
by Id: replace scale =5 if exp_quitter[_n-5]==1
by Id: replace scale =6 if exp_quitter[_n-6]==1
by Id: replace scale =-1 if exp_quitter[_n+1]==1
by Id: replace scale =-2 if exp_quitter[_n+2]==1
by Id: replace scale =-3 if exp_quitter[_n+3]==1
by Id: replace scale =-4 if exp_quitter[_n+4]==1
by Id: replace scale =-5 if exp_quitter[_n+5]==1
by Id: replace scale =-6 if exp_quitter[_n+6]==1
//cross sectional relationship
forvalues j=1/4  {
xi: reg lmu_`j' exportdum l* k* i.industry*i.year
* computing markup difference for tables
gen theta_`j'_1=_b[exportdum]
//mu_exp directly comparable to previous version and hall approach, i.e. level difference in markup
}
* do the same with productivity: here for translog
xi:reg lmu_tl omega_tl l k i.industry*i.year
gen theta_omega=_b[omega_tl]
*do the same with both productivity and exporting
xi: reg lmu_tl exportdum omega_tl l* k* i.industry*i.year
gen theta_1_omega=_b[exportdum]
//time series relationship
* produce percentage difference:
gen entry_effect=starter*exportdum
* value entry_effect is 1 post export entry
gen exit_effect=stopper*exportdum
* value exit_effect is 1 pre export exit, so take - coefficient for effect.
forvalues j=1/4 {
xi: reg lmu_`j' entry_effect exit_effect alwaysexporters l k i.year i.nace2 if switcher==.
gen gamma_`j'_0=_b[_cons]
gen gamma_`j'_0_se=_se[_cons]
gen gamma_`j'_1=_b[entry_effect]
gen gamma_`j'_1_se=_se[entry_effect]
gen gamma_`j'_2=-_b[exit_effect]
gen gamma_`j'_2_se=_se[exit_effect]
gen gamma_`j'_3=_b[alwaysexporters]
gen gamma_`j'_3_se=_se[alwaysexporters]
//mu_start directly comparable to previous version and hall approach, i.e. level difference in markup
gen mu_start`j'=gamma_`j'_1*exp(gamma_`j'_0)
}
* again with productivity included:
xi: reg lmu_`j' entry_effect exit_effect alwaysexporters l k omega_tl i.year*i.industry if switcher==.
*gen gamma_2_exp=_b[entry_effect]
}
*cross sectional results, markup premium exporters: precentage and levels: Table 3
tabstat theta_* mu_exp*
*cross sectional results: percentage export premium controlling for productivity: text paper
tabstat theta_1_omega
*cross sectional results: productivity-markup relationship: text paper
tabstat theta_omega
*time series results: percentage difference before-after export entry/exit, and always exporting: Table 4
tabstat gamma_1*
tabstat gamma_2*
tabstat gamma_3*
tabstat gamma_4*
*time series results comparable to previous version and Hall: level difference: Table 4
tabstat mu_start*

* entry export result around equation 26:
gen exportshare=S_E/S
gen entry_effect_share=entry_effect*exportshare
xi: reg lmu_`j' entry_effect entry_effect_share exit_effect alwaysexporters l k i.year*i.industry if switcher==.

* markups and export destination
*let R1 be the region dummy of Western Europe where we consider Slovenia and ex-Yugoslavia as constant term
xi: reg lmu_`j' exportdum*R1 l k i.industry*i.year, cluster(region)
* coefficients on interaction term give markup premium for a region; we include various region dummies (US-CAN, West-Europe, Asia, others).
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*






