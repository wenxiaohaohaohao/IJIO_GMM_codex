/*	Market Structure, Oligopsony Power, and Productivity
			(Michael Rubens, UCLA)

			- ACF PF ESTIMATION: BOOTSTRAPPING -
========================================================*/

cd "$station"
set more off

local B = $B    //200   //200  //200  //50  //250  // # bootstrap iterations
local M = max(10,`B')

set matsize `M'

use ./Data/china_tobacco_data, clear

replace ssub = . if rev==0

xtset fid yr
 
  
/* 0. Make vectors to store coefficient estimates
------------------------------------------------*/

* Matrices to store estimates

// Production model

foreach model in "acf1" "acf2"  {
foreach coef in "beta_l" "beta_k" "beta_x1" "beta_x2" "scale" "md" {
matrix _`coef'_`model' = J(`B', 1, 0)
matrix m_`coef'_`model' = J(`B', 1, 0)
}
}

  
// Treatment effects

foreach model in "acf1" "acf2"  {
foreach coef in  "th_lmd" "th_ltfp"  {
forvalues m = 6(2)6 {
matrix _`coef'_`model'_dq`m' = J(`B', 1, 0)		// average
matrix m_`coef'_`model'_dq`m' = J(`B', 1, 0) 	// median
}
}
}

// Start bootstrapping iteration

forvalues b = 1/`B' {
preserve
use ./tempfiles/data_pf_bb, clear
set seed `b'							// seeds for bootstrap iterations: 1-200
bsample, cluster(fid) idcluster(idb)  	// block bootstrap: resample entire firm time series.
replace fid = idb

di "iteration " `b'
 
/* 1. Leaf market shares
----------------------------*/
  
global share = 0.117647  
* gen const = 1

forvalues m = 2(2)6 {
bys dq`m'id yr: egen pop_lab_dq`m' = sum(pop_lab)
bys dq`m'id yr: egen poptab_dq`m' = sum(q*$share)
gen qshare_dq`m' = q*$share/pop_lab_dq`m'
gen lqshare_dq`m' = log(qshare_dq`m')
gen qshare_nest_dq`m' = q*$share/poptab_dq`m'
gen lqshare_nest_dq`m' = log(qshare_nest_dq`m')
gen oo_dq`m' = (pop_lab_dq`m'-poptab_dq`m')/pop_lab_dq`m'
gen loo_dq`m' =  log(oo_dq`m')
gen lhs_dq`m' = lqshare_dq`m' - loo_dq`m'	
}

/* 2. Production function estimation
------------------------------------------------------------------- */

/* a. ACF with exogenous market structure */
 
save ./tempfiles/data_temp, replace

// 1st stage
xtset fid yr		
rename (lemp emp lk k   q p lp uw luw ) (l L k K  Q P p UW uw)		// rename for creating polynomials
gen y = lq

gen l_lag = L.l
gen k_lag = L.k

*gen dumobs_lag = L.dumobs
save ./tempfiles/data_pf, replace

do ./appendix/china_tobacco_acf_exgexit_stage1.do		// First stage regression

// 2nd stage

do ./appendix/china_tobacco_acf_exgexit.do				// Second stage

gen beta_c_acf1 = beta_lin[1,1]
gen beta_l_acf1 = beta_lin[2,1]
gen beta_k_acf1 = beta_lin[3,1]
gen beta_p_acf1 = beta_lin[4,1]
gen beta_w_acf1 = beta_lin[5,1]
gen scale_acf1 = beta_l_acf1 + beta_k_acf1
sum beta*

collapse beta* scale*, by(const)			// save the results
save ./tempfiles/pf_lk_coefs_acf1, replace

// Retrieve PF estimates in master program

use ./tempfiles/data_temp, clear

merge m:1 const using ./tempfiles/pf_lk_coefs_acf1, nogen

gen ltfp_acf1 = lq  - beta_l_acf1*lemp - beta_k_acf1*lk - beta_c_acf1	// tfp residual acf
gen tfp_acf1=exp(ltfp_acf1)
 

/* b. ACF with endogenous market structure */

xtset fid yr
gen dexit = open == 1 & L.open==.
replace dexit =1 if open == 1 & L.open==0

probit dexit lk lemp lp luw 
predict px 
sum px
gen px_lag= L.px


save ./tempfiles/data_temp, replace

// 1st stage
xtset fid yr		
rename (lemp emp lk k   q p lp uw luw ) (l L k K  Q P p UW uw)		// rename for creating polynomials
gen y = lq

gen l_lag = L.l
gen k_lag = L.k
*gen dumobs_lag = L.dumobs
save ./tempfiles/data_pf, replace

do ./appendix/china_tobacco_acf_endexit_stage1.do		// First stage regression

// 2nd stage

do ./appendix/china_tobacco_acf_endexit.do				// Second stage

gen beta_c_acf2 = beta_lin[1,1]
gen beta_l_acf2 = beta_lin[2,1]
gen beta_k_acf2 = beta_lin[3,1]
gen beta_p_acf2 = beta_lin[4,1]
gen beta_w_acf2 = beta_lin[5,1]
gen scale_acf2 = beta_l_acf2 + beta_k_acf2
sum beta*

collapse beta* scale*, by(const)			// save the results
save ./tempfiles/pf_lk_coefs_acf2, replace

// Retrieve PF estimates in master program

use ./tempfiles/data_temp, clear

merge m:1 const using ./tempfiles/pf_lk_coefs_acf2, nogen

gen ltfp_acf2 = lq  - beta_l_acf2*lemp - beta_k_acf2*lk - beta_c_acf2	// tfp residual acf
gen tfp_acf2=exp(ltfp_acf2)
  
 
/* Markdowns */
 
// Revenue shares

gen alphaL = w/rev
gen alphaM = m/rev
 gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.
sum alphaL alphaM, d

forvalues n = 1/2 {
gen md_acf`n'= (1/alphaM)*(1-alphaL/beta_l_acf`n')
gen mu_acf`n'= 1
gen lmu_acf`n' = 0
gen lmd_acf`n' = log(md_acf`n')
}
   
/* 3. Consolidation treatment effects
-----------------------------------------*/

 sum ltfp_acf*

forvalues m = 6(2)6 {
forvalues n = 1(1)2 {
foreach mod in   "acf" {
foreach var in "md"  "tfp" {
areg l`var'_`mod'`n'  treat02_dq`m'  post02   yr if dumobs==1 ,   absorb(fid) r 
gen th_l`var'_`mod'`n'_dq`m'=_b[treat02_dq`m']
local r2 = e(r2)
local r2_`var'_`mod'`n'_dq`m' = substr("`r2'",1,4)
local N_`var'_`mod'`n'_dq`m' = e(N)
}
}
}
}
 

* Markdown and markup moments
foreach var in "md_acf1" "md_acf2"  {
egen _`var' = mean(`var')
egen m_`var' = median(`var')
global a_`var' = _`var' 
global m_`var' = m_`var' 
}

drop _m* m_m*
 
  
foreach var of varlist md*  mu* th* beta_l* beta_k*  scale*  {
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

sum beta* md* th*
 
restore			// end bootstrapping loop here

}


** Store estimates from each bootstrapping iteration in the matrices

* Production and input supply model

foreach model in "acf1" "acf2" {
foreach coef in "beta_l"  "beta_k" "beta_x1" "beta_x2" "scale"    {
 svmat _`coef'_`model'  
}
}

foreach model in "acf1" "acf2" {
foreach coef in  "md"   {
 svmat _`coef'_`model'  
 svmat m_`coef'_`model'  
}
}


forvalues n = 1(1)2 {
foreach coef in  "th_lmd" "th_ltfp" {
forvalues m = 6(2)6 {
 svmat _`coef'_acf`n'_dq`m' 
 svmat  m_`coef'_acf`n'_dq`m'  
}
}
}

keep in 1/`B'

save ./tempfiles/estimates_bs, replace
 
use ./tempfiles/estimates_bs, clear
 
sum _md*, d
sum _th*, d

** Standard errors for table 2
  
* Production function

foreach mod in "acf1" "acf2" {
egen bl = sd(_beta_l_`mod')
egen bk = sd(_beta_k_`mod')
egen scale = sd(_scale_`mod')
estpost su bl bk scale
est store pf_`mod'_se
drop bl bk scale
}
 
* Markdowns   


forvalues n = 1(1)2 {
egen a_md  = sd(_md_acf`n') 
egen m_md  = sd(m_md_acf`n')  
estpost su a_md m_md  
est store md_acf`n'_se
drop a_md m_md 
}

** Standard errors for table 3

* Markdowns and productivity
 

 sum _th_ltfp_acf1_dq6

forvalues m = 6(2)6 {
forvalues n = 1(1)2 {
foreach var in "lmd" "ltfp"   {
egen th = sd(_th_`var'_acf`n'_dq`m')
estpost su th 
est store th_`var'_acf`n'_dq`m'_se
drop th
}
}
}  
