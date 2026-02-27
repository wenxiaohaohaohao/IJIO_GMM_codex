/*	Market structure, oligopsony power, and productivity
					(Michael Rubens, UCLA)

					- ROBUSTNESS CHECKS -
============================================================================*/

cd "$station"
set more off
  
use ./Data/china_tobacco_data, clear
xtset fid yr
  
/* 1. Production function
------------------------------------------------*/
gen alphaL = w/rev
gen alphaM = m/rev
gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.

/* Baseline spec.   */

xtset fid yr
foreach var of varlist lq lk lemp treat_dq6 treat02_dq6 post02 luw lp lm{
gen `var'_lag = L.`var'		// make lagged variables
} 

gmm (lq - {rho}*L.lq - ({bk})*(lk-{rho}*L.lk) - {bl}*(lemp - {rho}*L.lemp)  - {bp}*(lp - {rho}*L.lp) ///
 - {bc1}*(treat02_dq6 - {rho}*L.treat02_dq6) - {bc2}*(treat_dq6 - {rho}*L.treat_dq6)- {bc3}*(post02 - {rho}*L.post02)- {bw}*(luw - {rho}*L.luw)  - {c}*(1-{rho}) )   , ///
inst(lk   luw lp    L.lemp    L.lk L.lp   L.luw treat_dq6 treat02_dq6 post02 )    

matrix pfest_end = e(b)

gen beta_k_bb = pfest_end[1,2]
gen beta_l_bb = pfest_end[1,3]
gen beta_p_bb = pfest_end[1,4]
gen beta_c1_bb = pfest_end[1,5]
gen beta_c2_bb = pfest_end[1,6]
gen beta_c3_bb = pfest_end[1,7]
gen beta_uw_bb = pfest_end[1,8]
gen beta_c_bb = pfest_end[1,9]
gen scale_bb = beta_k_bb + beta_l_bb 
 

gen ltfp_bb = lq - beta_l_bb*lemp - beta_k_bb*lk   - beta_c_bb 		// make tfp residual
gen tfp_bb = exp(ltfp_bb)

xtset fid yr
 
gen dx = open==1 & F.open==0	
   
 
/* Translog */
gen lemp2 = lemp^2
gen lk2 = lk^2
gen lemplk = lemp*lk
foreach var of varlist lemp2 lk2 lemplk   {
gen `var'_lag = L.`var'
} 
gen lemp_laglk = lemp_lag*lk
gen lemp_laglk_lag = lemp_lag*lk_lag

gmm (lq - {rho}*L.lq - ({bk})*(lk-{rho}*L.lk) - {bl}*(lemp - {rho}*L.lemp) - {bl2}*(lemp2 - {rho}*L.lemp2) ///
- {bk2}*(lk2 - {rho}*L.lk2) - {blk}*(lemplk - {rho}*L.lemplk) - {bp}*(lp - {rho}*L.lp)  - {bw}*(luw - {rho}*L.luw)  - {c}*(1-{rho})  - {bc1}*(treat02_dq6 - {rho}*L.treat02_dq6) - {bc2}*(treat_dq6 - {rho}*L.treat_dq6)- {bc3}*(post02 - {rho}*L.post02) )   , ///
inst(lk   luw lp  L.lemp    L.lk L.lp   L.lemp2 lk2 L.lk2 lemp_laglk_lag L.luw lemp_laglk treat_dq6 post02 treat02_dq6) 
 
local N_tl = e(N)
di `N_tl'

matrix pfest_tl = e(b)
mat list pfest_tl

gen tl_rho = pfest_tl[1,1]
gen tl_k = pfest_tl[1,2]
gen tl_l = pfest_tl[1,3]
gen tl_ll = pfest_tl[1,4]
gen tl_kk= pfest_tl[1,5]
gen tl_lk = pfest_tl[1,6]
gen tl_p = pfest_tl[1,7]
gen tl_w = pfest_tl[1,8]
gen tl_c = pfest_tl[1,9]
gen tl_c1 = pfest_tl[1,10]
gen tl_c2 = pfest_tl[1,11]
gen tl_c3 = pfest_tl[1,12]

gen beta_l_tl = tl_l + 2*tl_ll *lemp + tl_lk *lk
gen beta_k_tl = tl_k + 2*tl_kk *lk + tl_lk *lemp
gen scale_tl = beta_l_tl+beta_k_tl

sum beta_l_tl beta_k_tl scale_tl 	// table A7a 

* save estimates for table A7a, first column

gen bk = beta_k_tl 
gen bl = beta_l_tl 
gen scale = scale_tl
estpost su bl bk scale
est store pf_tl
drop bl bk scale

// R^2

preserve
gen obs = lq~=. & L.lq~=. & lk~=. & L.lk~=. & lemp~=. & L.lemp~=.  & lp~=. & L.lp~=. & luw~=. & L.luw~=.
keep if obs ==1
gen lqhat = tl_k*lk  + tl_l*lemp + tl_lk*lk*lemp  + tl_ll*lemp*lemp + tl_kk*lk*lk + tl_p*lp + tl_w*luw + tl_c + tl_c1*treat02_dq6 + tl_c2*treat_dq6 + tl_c3*post02
egen avlq = mean(lq)
gen eps = (lq-lqhat)^2
gen var = (lq-avlq)^2
collapse(sum) eps var
gen r2 = 1 - eps/var
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_tl = substr("`r2'",1,4)
drop r2 r2s
restore
   
/* 2. Model with labor-augmenting technological change 
--------------------------------------------------------*/
  
foreach var in "m" "k" {
gen lhs_`var' = log(`var'/emp)
 
ivregress 2sls lhs_`var' (luw = dexp_ot pctexp_ot )   i.typeid dhs* i.yr dexp pctexp  lp if dumobs==1, r   first
gen sigma_`var' = _b[luw]
gen sigma_`var'_se = _se[luw]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_sigma_`var' = substr("`r2'",1,4)
drop r2 r2s
local N_sigma_`var' = e(N)
   
gen sigma = sigma_`var'
estpost su sigma
est store sigma_`var'
replace sigma = sigma_`var'_se
estpost su sigma 
est store sigma_`var'_se
drop sigma
}
 
 
gen lkemp = log(k/emp)
areg lkemp treat02_dq6 treat_dq6 yr, absorb(fid) cluster(dq6id)
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_kemp = substr("`r2'",1,4)
drop r2 r2s

local N_kemp = e(N)
gen th_bkemp = _b[treat02_dq6]
gen th_sekemp = _se[treat02_dq6] 


gen th_kemp = th_bkemp
estpost su th_kemp
est store th_kemp 
replace th_kemp = th_sekemp
estpost su th_kemp 
est store th_kemp_se
drop th_kemp 

gen inv = D.k
gen cs_l = w/(w +inv)
gen cs_k = inv/(w+inv)
bys yr: egen beta_l_lap = median(cs_l)
bys yr: egen beta_k_lap = median(cs_k)   

gen scale_lap = beta_l_lap + beta_k_lap

gen ltfp_lap = lq - beta_l_lap*lemp - beta_k_lap*lk   		// make tfp residual
gen tfp_lap = exp(ltfp_lap)

// R^2
preserve
xtset fid yr
keep if ltfp_lap~=. & L.ltfp_lap~=. 
gen lqhat = beta_l_lap*lemp + beta_k_lap*lk  
reg lqhat lq

egen avlq = mean(lq)
gen eps = (lq-lqhat)^2
gen var = (lq-avlq)^2
collapse(sum) eps var

gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_lap = substr("`r2'",1,4)
drop r2 r2s


local N_lap = e(N)
restore

// save results for table A7a, 2nd column 
gen bl = beta_l_lap
gen bk = beta_k_lap
gen scale = scale_lap
estpost su bl bk scale
est store pf_lap
drop bl bk  scale
  
  
/*  Calculate productivity residuals */
 

gen ltfp_tl = lq - tl_l*lemp - tl_k*lk - tl_ll*lemp^2 - tl_kk*lk^2  - tl_lk*lemp*lk
gen tfp_tl = exp(ltfp_tl)

corr tfp*
corr ltfp*
   

foreach mod in "tl" "bb"  {
 
gen md_`mod' = (1/alphaM)*(1-alphaL/beta_l_`mod')
gen lmd_`mod'  = log(md_`mod')
} 

sum md* if dumobs==1, d		// table A7b

/* 3. Different markup calibrations
--------------------------------------------------------*/

// Markups and markdowns
 
local m = 6	// market definition 

gen md_rob1 = (1/alphaM)*(1/(0.644)-alphaL/beta_l_bb)
gen md_rob2 = (1/alphaM)*(1/(1 )-alphaL/beta_l_bb)
gen md_rob3 = (1/alphaM)*(1/(1.502)-alphaL/beta_l_bb)

forvalues m = 1/3 {
gen rob`m' = md_rob`m'
}

estpost su rob1 rob2 rob3 if dumobs==1		// table A9 column 1
est store md_rob

foreach var of varlist md_rob* {
	gen l`var' = log(`var')
}
 
sum md_rob* , d

// Treatment effects

drop rob*

forvalues m = 1/3 {
areg lmd_rob`m' treat02_dq6  post02   yr  if dumobs==1 ,   absorb(fid) r 		// table A9 column 2
gen rob`m' = _b[treat02_dq6]
}
 
estpost su rob1 rob2 rob3
est store th_rob
  
gen md_lap   = (1/alphaM)*(1 -alphaL/beta_l_lap)
sum md_lap, d
 

gen lmd_lap = log(md_lap)


 // store markup/markdown variables for tables
 
 
foreach mod in "tl"   "lap"{
egen a_md = mean(md_`mod')
egen m_md  = median(md_`mod')
estpost su  a_md m_md 
est store md_`mod'
drop a_md m_md
}
  
 /* 4. Quality
--------------------------------------------------------*/
 
merge m:1 FRDM yr using ./data/quality/data_quality
drop if _merge==2
drop _merge
  
/* i. treatment effects */

sum qual, d
gen loqual = qual< 2.5
replace loqual = . if qual==.
drop ssub
gen ssub = sub/rev

reg dsub qual	// subsidy more likely for low quality products

areg loqual treat02_dq6 treat_dq6 post02 yr  , absorb(fid) cluster(dq6id)		// table A10a - column 1
gen bqual1 = _b[treat02_dq6]
gen sequal1 = _se[treat02_dq6]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_qual1 = substr("`r2'",1,4)
di "`r2_qual1'"
drop r2 r2s
local N_qual1 = e(N)

areg dsub treat02_dq6 treat_dq6 post02 yr, absorb(fid) cluster(dq6id)	// table A10a - column 2
gen bqual2 = _b[treat02_dq6]
gen sequal2 = _se[treat02_dq6]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_qual2 = substr("`r2'",1,4)
drop r2 r2s
local N_qual2 = e(N)

areg ssub treat02_dq6 treat_dq6 post02 yr, absorb(fid) cluster(dq6id)	// table A10a - column 3
gen bqual3 = _b[treat02_dq6]
gen sequal3 = _se[treat02_dq6]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_qual3 = substr("`r2'",1,4)
drop r2 r2s
local N_qual3 = e(N)
  
/* ii. serial correlation in quality */

areg loqual , absorb(fid) 
areg dsub , absorb(fid) 
areg ssub , absorb(fid) 

/* iii. markdown treatment effects */
 
areg lmd_bb treat02_dq6 treat_dq6  i.yr if dsub ~=. & dumobs==1, absorb(fid)	// table A10b - column 1
gen bmd1 = _b[treat02_dq6]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_bmd1 = substr("`r2'",1,4)
drop r2 r2s

local N_bmd1 = e(N)

areg lmd_bb treat02_dq6 treat_dq6  i.yr dsub if dsub ~=. & dumobs==1, absorb(fid)	// table A10b - column 2	
gen bmd2 = _b[treat02_dq6]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_bmd2 = substr("`r2'",1,4)
drop r2 r2s
local N_bmd2 = e(N)

areg lmd_bb treat02_dq6 treat_dq6  i.yr dsub ssub if dsub ~=. & dumobs==1, absorb(fid)	// table A10b - column 3
gen bmd3 = _b[treat02_dq6]
gen r2 = e(r2)
gen str4 r2s = string(r2,"%04.2f")
local r2 = r2s
local r2_bmd3 = substr("`r2'",1,4)
drop r2 r2s
local N_bmd3 = e(N)
 
* Characteristics and market structure

bys dq6id yr: egen nf_dq6 = sum(open)
preserve 
drop if nf_dq6==0
tab nf_dq6, gen(nf_dq6_)

gen lchar_weigh = log(char_weigh)
collapse char_weigh nf*, by(dq6id)
gen lchar_weigh = log(char_weigh)
sum char_weigh,d
reg lchar_weigh nf_dq6_1 nf_dq6_2 , r	// table A8c

gen bweight_nf1 = _b[nf_dq6_1]
gen bweight_nf2 = _b[nf_dq6_2]
gen seweight_nf1 = _se[nf_dq6_1]
gen seweight_nf2 = _se[nf_dq6_2]
local r2 = e(r2)
local r2_weight = substr("`r2'",1,4)
local N_weight = e(N)
estpost su bweight*
est store bweight 
replace bweight_nf1 = seweight_nf1
replace bweight_nf2 = seweight_nf2
estpost su bweight*
est store bweight_se 
restore
  
* Store estimates

forvalues m = 1/3 {
gen bqual = bqual`m'
estpost su bqual  
est store bqual`m'
replace bqual = sequal`m'
estpost su bqual  
est store bqual`m'_se
drop bqual
} 

forvalues m = 1/3 {
gen bmd = bmd`m'
estpost su bmd
est store bmd`m'  
drop bmd
} 
  
/* 4. Treatment effects 
--------------------------*/


/* Different production models */

foreach model in   "tl"    "lap" {
local m = 6
areg lmd_`model'  treat02_dq`m' /*treat_dq`m'*/  post02 yr  if dumobs==1 , absorb(fid) r 
gen th_md_`model' = _b[treat02_dq`m']
areg ltfp_`model' treat02_dq`m' /*treat_dq`m'*/ post02 yr if dumobs==1, absorb(fid) r 
gen th_tfp_`model' = _b[treat02_dq`m']
local N_th_`model'= e(N)
}
 

// save to tables
foreach mod in   "tl"   "lap" {
foreach var in   "md" "tfp"   {
gen th_`var' = th_`var'_`mod'
}
estpost su th_md  th_tfp  
est store th_`mod'
drop th_md   th_tfp  
}


/* Different market definitions: table A8 */

foreach model in "bb" {
forvalues m = 2(2)6 {
areg lmd_`model'  treat02_dq`m' post02  yr if dumobs==1 , absorb(fid) r 
gen th_md_`model'_dq`m'  = _b[treat02_dq`m']
areg ltfp_`model' treat02_dq`m' post02 yr if dumobs==1, absorb(fid) r 
gen th_tfp_`model'_dq`m'_dq`m' = _b[treat02_dq`m']
}
}
 
  
foreach var in  "md" "tfp" {
forvalues m = 2(2)6 {
gen th_dq`m' = th_`var'_bb_dq`m'
}
estpost su th_dq2 th_dq4 th_dq6
est store th_`var'
drop th_dq*
}
  
// Drop  firms under 100K (except nonSOEs)
 
forvalues m = 6(2)6 {
foreach var in  "md" "tfp" {
areg l`var'_bb  treat02_dq`m'  post02 yr  if dumobs==1  | typeid~=1 & under100K==0, absorb(fid) r 
gen th_`var'_under100K  = _b[treat02_dq`m']
}
}

foreach var in  "md" "tfp" {
gen th_under100K = th_`var'_under100K
estpost su th_under100K
est store th_`var'_under100K
drop th_under100K
} 
 
/* Bootstrapping */
do ./bootstrap/china_tobacco_ap_robchecks_bs
 
*** Make tables
   
 
** Table A5 - elasticity of substitution

gen sigma =1
label var sigma "Elasticity of substitution"
esttab  sigma_m sigma_m_se  sigma_k sigma_k_se  using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA5.tex", replace ///
prehead("\textit{panel A: Elasticity of substitution}" & \multicolumn{2}{c}{Labor and leaf}&  \multicolumn{2}{c}{Labor and capital}    \\ \cline{2-5})   ///
mtitle("Est." "S.E." "Est." "S.E." ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em} \\ \vspace{0.25em} 1st stage F-stat &  \multicolumn{2}{c}{38.52} &  \multicolumn{2}{c}{38.52} \vspace{0.25em} \\   ///
R-squared &  \multicolumn{2}{c}{`r2_sigma_m'} &  \multicolumn{2}{c}{`r2_sigma_k'} \vspace{0.5em}  \\ Observations &  \multicolumn{2}{c}{`N_sigma_m'} &  \multicolumn{2}{c}{`N_sigma_k'}  \vspace{0.5em}  \\ \hline )  posthead( \hline &&&\\   ) 
drop sigma
 
gen th_kemp =1
label var th_kemp "1(Treatment)*1(year$>$2002)"
esttab  th_kemp th_kemp_se using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA5.tex", append ///
prehead("\textit{panel B: Capital intensity changes}" & \multicolumn{2}{c}{log(Capital/labor)}    \\ \cline{2-3})   ///
mtitle("Est." "S.E."   ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em} \\  R-squared &  \multicolumn{2}{c}{`r2_kemp'}  \vspace{0.5em}  \\ Observations &  \multicolumn{2}{c}{`N_kemp'}   \vspace{0.5em}   \\ \hline )  posthead( \hline &\\   ) 
 

** Table A7: Alternative production models

* PF coefs

gen bl = 1
gen bk = 1
gen scale = 1
label var bl "Output elasticity of labor"
label var bk "Output elasticity of capital"
label var scale "Returns to scale"

esttab pf_tl pf_tl_se   pf_lap pf_lap_se     using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA7.tex", replace ///
prehead("\textit{panel A: Production function}" & \multicolumn{2}{c}{Translog}  & \multicolumn{2}{c}{Cost shares}     \\ \cline{2-5})   ///
 mtitle("Est." "S.E."   "Est." "S.E.")   ///
cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em} \\ \vspace{0.25em}  R-squared &  \multicolumn{2}{c}{`r2_tl' }   &  \multicolumn{2}{c}{`r2_lap'}   ///
\vspace{0.25em}  \\ Observations &  \multicolumn{2}{c}{`N_tl'}    &  \multicolumn{2}{c}{`N_lap'}\vspace{0.5em}   \\  )  posthead( \hline &&&\\   ) 
drop bl bk   

// Markdowns

gen m_md = 1
gen a_md = 1

label var a_md "Avg. markdown"
label var m_md "Med. markdown"

esttab md_tl md_tl_se /*md_end md_end_se*/ md_lap md_lap_se  using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA7.tex", append ///
prehead(\hline "\textit{panel B: Markdowns}" & \multicolumn{2}{c}{Translog}    & \multicolumn{2}{c}{Cost shares}   \\ \cline{2-5})   ///
 mtitle("Est." "S.E." "Est." "S.E."  "Est." "S.E."  ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em}    \\  )  posthead( \hline &&&\\   ) 
drop   a_md m_md

gen th_md = 1
gen th_tfp = 1
 
// Treatment effects

label var th_md "Markdown effect"
label var th_tfp "TFP effect" 
 
esttab th_tl th_tl_se   th_lap th_lap_se   using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA7.tex", append //////
prehead(\hline "\textit{panel C: Consolidation treatment effects}" & \multicolumn{2}{c}{Translog}   & \multicolumn{2}{c}{Cost shares}   \\ \cline{2-5})   ///
mtitle("Est." "S.E."   "Est." "S.E."  ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em} \\ ///
\vspace{0.25em}   Observations &  \multicolumn{2}{c}{`N_th_tl'}  &  \multicolumn{2}{c}{`N_th_lap'}     \\ \hline )  posthead( \hline &&&\\   ) 
 
 
* Table A8: Robustness checks

// A8a: Different leaf market definitions
foreach var in "th_dq2" "th_dq4" "th_dq6"  {
gen `var' = 1
}
label var th_dq6 "County-level treatment"
label var th_dq4 "Prefecture-level treatment"
label var th_dq2 "Province-level treatment"
 
esttab th_md th_md_se   th_tfp th_tfp_se  using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA8.tex", replace ///
prehead(    \textit{panel A: Different market definitions} & \multicolumn{2}{c}{log(Markdown)}&  \multicolumn{2}{c}{log(TFP)}   \\ \cline{2-5})   ///
mtitle("Est." "S.E." "Est." "S.E."  ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f  prefoot(\vspace{-0.75em} \\ \hline)  posthead( \hline &&&\\   ) 

// A8b Only large firms

gen th_under100K = .
label var th_under100K "1(Treatment) *1(year$>$2002)"

esttab th_md_under100K th_md_under100K_se th_tfp_under100K th_tfp_under100K_se  using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA8.tex", append ///
prehead(    \textit{panel B: Dropping small firms} & \multicolumn{2}{c}{log(Markdown)}&  \multicolumn{2}{c}{log(TFP)}   \\ \cline{2-5})   ///
mtitle("Est." "S.E." "Est." "S.E."  ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f  prefoot(\vspace{-0.75em} \\ \hline)  posthead( \hline &&&\\   ) 

// A8c Leaf content of cigarettes

gen bweight_nf1 = .
gen bweight_nf2 = .
label var bweight_nf1 "1(One firm in the county)"
label var bweight_nf2 "1(Two firms in the county)"

esttab bweight bweight_se  using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA8.tex", append ///
prehead(    \textit{panel C: Leaf content variation} & \multicolumn{2}{c}{log(Leaf content per cigarette)}& &  \\ \cline{2-5})   ///
mtitle("Est." "S.E."  "" ""   ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f  prefoot(\vspace{-0.75em} \\ \hline)  posthead( \hline &&&\\   ) 


* Table A9: Different markup values


forvalues m = 1/3{
gen rob`m'=.
}

label var  rob1 "$\mu = 0.644$"
label var  rob2 "$\mu = 1.000$"
label var  rob3 "$\mu = 1.502$"

esttab md_rob md_rob_se th_rob th_rob_se  using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA9.tex", replace ///
prehead(  & \multicolumn{2}{c}{Markdown level}    & \multicolumn{2}{c}{Treatment effect}   \\ \cline{2-5})   ///
 mtitle("Est." "S.E." "Est." "S.E."  "Est." "S.E."  ) cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f   postfoot(\hline)  prefoot(\vspace{-0.75em}    \\  )  posthead( \hline &&&\\   ) 
 

* Table A10: quality 

gen bmd = .
label var bmd "1(Treatment) *1(year$>$2002)"
gen bqual = .
label var bqual "1(Treatment) *1(year$>$2002)"

esttab bqual1 bqual1_se bqual2 bqual2_se bqual3 bqual3_se      using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA10.tex", replace ///
prehead("\textit{panel A: Quality and consolidation}" & \multicolumn{2}{c}{1(Low quality)}& \multicolumn{2}{c}{1(Subsidy)}   & \multicolumn{2}{c}{Subsidy/Revenue}     \\ \cline{2-7})   ///
 mtitle("Est." "S.E." "Est." "S.E."  "Est." "S.E.")   ///
cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em} \\ \vspace{0.25em}  R-squared &  \multicolumn{2}{c}{`r2_qual1'} &  \multicolumn{2}{c}{`r2_qual2'} &  \multicolumn{2}{c}{`r2_qual3'}   ///
\vspace{0.25em}  \\ Observations &  \multicolumn{2}{c}{`N_qual1'} &  \multicolumn{2}{c}{`N_qual2'}  &  \multicolumn{2}{c}{`N_qual3'}\vspace{0.5em}   \\ \hline )  posthead( \hline &&&\\   ) 

esttab bmd1 bmd1_se bmd2 bmd2_se bmd3 bmd3_se      using "/Users/MichaelRubens/Dropbox/China tobacco/Paper/aer_2021_0383/tables/tableA10.tex", append ///
prehead("\textit{panel B: Markdowns and consolidation}" & \multicolumn{2}{c}{log(Markdown)}& \multicolumn{2}{c}{log(Markdown)}   & \multicolumn{2}{c}{log(Markdown)}     \\ \cline{2-7})   ///
 mtitle("Est." "S.E." "Est." "S.E."  "Est." "S.E.")   ///
cells(mean(fmt(3))) label booktabs nonum noobs collabels(none) gaps f     prefoot(\vspace{-0.75em} \\ \vspace{0.25em}  Control for subsidy dummy: &  \multicolumn{2}{c}{No} &  \multicolumn{2}{c}{Yes} &  \multicolumn{2}{c}{Yes} \vspace{0.25em} \\ ///
Control for subsidy/revenue: &  \multicolumn{2}{c}{No} &  \multicolumn{2}{c}{No} &  \multicolumn{2}{c}{Yes}  ///
\vspace{0.25em}  \\ \vspace{0.25em}  R-squared &  \multicolumn{2}{c}{`r2_bmd1'} &  \multicolumn{2}{c}{`r2_bmd2'} &  \multicolumn{2}{c}{`r2_bmd3'}   ///
\vspace{0.25em}  \\ Observations &  \multicolumn{2}{c}{`N_bmd1'} &  \multicolumn{2}{c}{`N_bmd2'}  &  \multicolumn{2}{c}{`N_bmd3'}\vspace{0.5em}   \\ \hline )  posthead( \hline &&&\\   ) 


 