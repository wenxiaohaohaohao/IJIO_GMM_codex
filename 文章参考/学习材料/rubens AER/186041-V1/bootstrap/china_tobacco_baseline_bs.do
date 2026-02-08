/*	Market Structure, Oligopsony Power, and Productivity
			(Michael Rubens, UCLA)

			- BASELINE MODEL: BOOTSTRAPPING -
========================================================*/

cd "$station"
set more off
 
local B = $B     // # bootstrap iterations
local M = max(10,`B')

set matsize `M'

use ./Data/china_tobacco_data, clear

xtset fid yr
gen const = 1
  
/* 0. Make vectors to store coefficient estimates
------------------------------------------------*/

* Matrices to store estimates

// Production model

foreach model in "bb" "ols"  {
foreach coef in "beta_l" "beta_k" "beta_x1" "beta_x2" "scale"  {
matrix _`coef'_`model' = J(`B', 1, 0)
matrix m_`coef'_`model' = J(`B', 1, 0)
}
}
 
// Markdown

forvalues n = 0(1)1 {
foreach coef in "md" "th_lmd" "th_ltfp" "th_lq" {
forvalues m = 2(2)6 {
matrix _`coef'`n'_dq`m' = J(`B', 1, 0)		// average
matrix m_`coef'`n'_dq`m' = J(`B', 1, 0) 	// median
}
}
}

// Aggregate TFP

foreach coef in "lagtfp_bb" "lavtfp_bb" "lreal_bb" "lagq" "lavq" "lrealq" {
forvalues m = 2(2)6 {
matrix _th_`coef'_dq`m' = J(`B', 1, 0)		// average
}
}

// Markdown determinants

forvalues n = 0(1)1 {
foreach coef in "dsoe" "lrev" "luerate" "lstax"  "nf_dq6_1" "nf_dq6_2" {
matrix _det_`coef' = J(`B', 1, 0)		// average
}
}

/* 1. Descriptive evidence
-------------------------------------*/

// In baseline file, not necessary to bootstrap standard errors.


/* 2. Production function estimation
-------------------------------------*/

xtset fid yr
foreach var of varlist lq lk lemp treat_dq4 treat02_dq4 post02 {
gen `var'_lag = L.`var'
}

save ./tempfiles/data_pf_bb, replace		// dataset to estimate production function

* Start bootstrapping iteration

forvalues b = 1/`B' {
preserve
use ./tempfiles/data_pf_bb, clear
set seed `b'
bsample, cluster(fid) idcluster(idb)  	// block bootstrap: resample entire firm time series.
replace fid = idb

di "iteration " `b'

* OLS  

reg lq lk lemp lp   luw  treat_dq6 treat02_dq6 post02  
gen beta_l_ols = _b[lemp]
gen beta_k_ols = _b[lk]
gen scale_ols = beta_l_ols + beta_k_ols

* GMM

xtset fid yr

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
  
gen ltfp_bb = lq - beta_l_bb*lemp - beta_k_bb*lk   - beta_c_bb	// make tfp residual
gen tfp_bb = exp(ltfp_bb)
 
 
/* 3. Markdown estimation  
-----------------------------------------------------------------*/

* Revenue shares

gen alphaM = m/rev
gen alphaL = w/rev  

gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.

gen lalphaM = log(1/alphaM)
areg lalphaM treat02_dq6 post02 yr      ,   absorb(fid) r 		// year dummies

* Markups and markdowns
 
forvalues m = 2(2)6 { 
gen md0_dq`m' = (1/alphaM)*(1 -alphaL/beta_l_bb)
gen md1_dq`m' = (1/alphaM)*(1 -alphaL/beta_l_ols)
forvalues n= 0/1{
gen mu`n'_dq`m'  =1
gen lmu`n'_dq`m'  =log(mu`n'_dq`m')
gen lmd`n'_dq`m'  = log(md`n'_dq`m')
gen ltfp`n'_dq`m' = ltfp_bb
}
} 
 
 
 
* Markdown determinants - heterogeneity
 
gen dsoe = typeid==1
gen luerate = log(pop_unemp/pop)
 
bys dq6id yr: egen nf_dq6 = sum(open)
drop if nf_dq6==0
tab nf_dq6, gen(nf_dq6_)

reg lmd0_dq6   dsoe lrev lstax  luerate     nf_dq6_1 nf_dq6_2   
mat coef_det = e(b)
 
gen det_dsoe = coef_det[1,1]
gen det_lrev = coef_det[1,2]
gen det_lstax = coef_det[1,3]
gen det_luerate = coef_det[1,4]
gen det_nf_dq6_1 = coef_det[1,5]
gen det_nf_dq6_2 = coef_det[1,6]
 
/* 4. Consolidation treatment effects
-----------------------------------------*/

// Treatment effects - baseline

forvalues n = 0(1)1  {
forvalues m = 2(2)6 {
gen lq`n'_dq`m'=lq
foreach var in "md" "tfp" "q"{
areg l`var'`n'_dq`m' treat02_dq`m'  post02   yr  if dumobs==1   ,   absorb(fid) r 
gen th_l`var'`n'_dq`m'=_b[treat02_dq`m']
}
}
}
  
// Treatment effects - reallocation at the aggregate level

save ./tempfiles/data_temp, replace
use ./tempfiles/data_temp, clear

local m = 2
local t = "02"
keep if tfp_bb~=.
keep if dumobs==1
bys dq`m'id yr: egen agq_dq`m' = sum(q)
bys dq`m'id yr: egen avq_dq`m' = mean(q)
bys yr: egen empyr = sum(emp)
gen sempyr = emp/empyr
gen wtfp_bb = tfp_bb*sempyr
bys dq`m'id yr: egen agtfp_bb = sum(wtfp_bb)
bys dq`m'id yr: egen avtfp_bb = mean(tfp_bb)
gen retfp_bb =  avtfp_bb-agtfp_bb
collapse(mean) avq_dq`m' agq_dq`m' avtfp_bb agtfp_bb retfp_bb, by(const yr dq`m'id treat_dq`m' treat`t'_dq`m' post`t')
foreach var of varlist    av* ag* {
gen l`var' = log(`var')
}
xtset dq`m'id yr
gen lreal_bb_dq`m' = lagtfp_bb - lavtfp_bb 
gen lrealq_dq`m' = lagq_dq`m'-lavq_dq`m'

foreach var in "lagtfp_bb" "lavtfp_bb" "lreal_bb" "lagq" "lavq" "lrealq"{ 
areg `var'   treat`t'_dq`m' post`t' treat_dq`m' yr , absorb(dq`m'id) r 
gen th_`var'_dq`m' = _b[treat`t'_dq`m']
local r2 = e(r2)
local r2_`var'_dq`m' = substr("`r2'",1,4)
local N_`var'_dq`m' = e(N)
}
collapse th*, by(const)
save ./tempfiles/th_agprod_dq`m', replace

use ./tempfiles/data_temp, clear
forvalues m = 2(2)2 {
merge m:1 const using ./tempfiles/th_agprod_dq`m', nogen update
}  
 

* Store all estimates

foreach var of varlist md*  mu* th* beta_l* beta_k*  scale* det* {
egen av`var' = mean(`var')  
egen med`var' = median(`var')  
}
 
keep in 1/`B'

foreach var of varlist  beta_l* beta_k*  th* scale*     {
 mkmat av`var', matrix(av`var')
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration in matrix	
}

  
foreach var of varlist  md*  {
 mkmat av`var' , matrix(av`var') 
 mkmat med`var' , matrix(med`var') 
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration in matrix
 matrix m_`var'[`b',1] = med`var'[1,1]			// store average markdown for this bootstrap iteration in matrix
}
 

foreach coef in "dsoe" "lrev" "luerate" "lstax"  "nf_dq6_1" "nf_dq6_2" {
mkmat avdet_`coef' , matrix(avdet_`coef') 
matrix _det_`coef'[`b',1] = avdet_`coef'[1,1]
}


restore			// end bootstrapping loop here
}


** Store estimates from each bootstrapping iteration in the matrices

* Production and input supply model

foreach model in "bb"  "ols" {
foreach coef in "beta_l" "beta_k" "beta_x1" "beta_x2" "scale"    {
 svmat _`coef'_`model'  
}
}

foreach coef in "dsoe" "lrev" "luerate" "lstax"  "nf_dq6_1" "nf_dq6_2" {
svmat _det_`coef' 
}



forvalues n = 0(1)1 {
foreach coef in "md" "th_lmd" "th_ltfp" {
forvalues m = 2(2)6 {
svmat _`coef'`n'_dq`m' 
 svmat  m_`coef'`n'_dq`m'  
}
}
}

*Aggregate TFP

foreach coef in "lagtfp_bb" "lavtfp_bb" "lreal_bb" "lavq" "lagq" "lrealq"{
forvalues m = 2(2)6 {
svmat _th_`coef'_dq`m'  
}
}

keep in 1/`B'

** Standard errors for table 2
  
* Production function

foreach mod in "bb" "ols" {
egen bl = sd(_beta_l_`mod')
egen bk = sd(_beta_k_`mod')
egen scale = sd(_scale_`mod')
estpost su bl bk scale
est store pf_`mod'_se
drop bl bk scale
}
 
* Markdowns   

forvalues m = 6(2)6 {
forvalues n = 0(1)1 {
egen a_md = pctile(_md`n'_dq`m'), p(5)
egen m_md = pctile(m_md`n'_dq`m'), p(5)
estpost su a_md m_md 
est store md`n'_dq`m'_p5
drop a_md m_md  

egen a_md = pctile(_md`n'_dq`m'), p(95)
egen m_md = pctile(m_md`n'_dq`m'), p(95)
estpost su a_md m_md 
est store md`n'_dq`m'_p95
drop a_md m_md  

egen a_md  = sd(_md`n'_dq`m') 
egen m_md  = sd(m_md`n'_dq`m')  
estpost su a_md m_md  
est store md`n'_dq`m'_se
drop a_md m_md 
}
}

* Markdown determinants

foreach coef in "dsoe" "lrev" "luerate" "lstax"  "nf_dq6_1" "nf_dq6_2" {
egen det_`coef' = sd(_det_`coef')
}

// save to table

estpost su det* 
est store det_md_se
drop det*

** Standard errors for table 3

* Markdowns and productivity
 
 
forvalues m = 6(2)6 {
forvalues n = 0(1)1 {
foreach var in "lmd" "ltfp"   {
egen th = sd(_th_`var'`n'_dq`m')
estpost su th 
est store th_`var'`n'_dq`m'_se
drop th
}
}
}
* Allocative efficiency

forvalues m = 2(2)2 {
foreach var in "lavtfp_bb" "lagtfp_bb" "lreal_bb" {
egen th = sd(_th_`var'_dq`m')
estpost su th 
est store th_`var'_dq`m'_se
drop th
}
}

* Output

forvalues m = 2(2)2 {
foreach var in "lavq" "lagq" "lrealq" {
egen th = sd(_th_`var'_dq`m')
estpost su th 
est store th_`var'_dq`m'_se
drop th
}
}
