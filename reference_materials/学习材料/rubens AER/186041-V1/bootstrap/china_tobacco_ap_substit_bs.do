/*	Market Structure, Oligopsony Power, and Productivity
			(Michael Rubens, UCLA)

- SUBSTITUTABLE LEAF AND LATC EXTENSIONS: BOOTSTRAPPING -
========================================================*/

cd "$station"
set more off

local B = $B    //200   //200  //200  //50  //250  // # bootstrap iterations
local M = max(10,`B')

set matsize `M'

use ./Data/china_tobacco_data, clear

xtset fid yr
gen const = 1
  
  
  
/* 0. Make vectors to store coefficient estimates
------------------------------------------------*/

* Matrices to store estimates

// Production model


foreach model in "sub"    {
foreach coef in "beta_l" "beta_k" "beta_m"  "scale"   {
matrix _`coef'_`model' = J(`B', 1, 0)
matrix m_`coef'_`model' = J(`B', 1, 0)
}
}
 
// Markdown

foreach mod in "sub"  { 
foreach coef in "md" "th_lmd" "mu" "th_ltfp" "th_lq" {
matrix _`coef'_`mod' = J(`B', 1, 0)		// average
matrix m_`coef'_`mod' = J(`B', 1, 0) 	// median
}
}

save ./tempfiles/data_pf_bb, replace

forvalues b = 1/`B' {
preserve
use ./tempfiles/data_pf_bb, clear
set seed `b'
bsample, cluster(fid) idcluster(idb)  	// block bootstrap: resample entire firm time series.
replace fid = idb

di "iteration " `b'

gen alphaL = w/rev
gen alphaM = m/rev
gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.

/* 2. Production function
---------------------------*/

/* Dynamic panel approach */

xtset fid yr
foreach var of varlist lq lk lemp treat_dq4 treat02_dq4 post02 luw lp lm{
gen `var'_lag = L.`var'		// make lagged variables
} 

gmm (lq - {rho}*L.lq - ({bk})*(lk-{rho}*L.lk) - {bl}*(lemp - {rho}*L.lemp) - {bm}*(lm - {rho}*L.lm) - {bp}*(lp - {rho}*L.lp)  - {bw}*(luw - {rho}*L.luw) - {bc1}*(treat02_dq6 - {rho}*L.treat02_dq6) - {bc2}*(treat_dq6 - {rho}*L.treat_dq6)- {bc3}*(post02 - {rho}*L.post02) - {c}*(1-{rho}) )     	  , ///	
inst(lk      L.lemp   lp luw L.lk L.lp   L.luw L.lm treat02_dq6 treat_dq6 post02 L.treat02_dq6 L.treat_dq6 L.post02 )   conv_maxiter(50)
 
local N_pf_bb= e(N)

mat sub_coef = e(b)

gen beta_k_sub = sub_coef[1,2]
gen beta_l_sub = sub_coef[1,3]
gen beta_m_sub = sub_coef[1,4]
gen beta_p_sub = sub_coef[1,5]
gen beta_w_sub = sub_coef[1,6]
gen beta_c1_sub = sub_coef[1,7]
gen beta_c2_sub = sub_coef[1,8]
gen beta_c3_sub = sub_coef[1,9]
gen beta_c_sub = sub_coef[1,10]
gen scale_sub = beta_l_sub + beta_k_sub+ beta_m_sub
 
gen ltfp_sub = lq - beta_l_sub*lemp - beta_k_sub*lk - beta_m_sub*lm   - beta_c_sub 		// make tfp residual
gen tfp_sub = exp(ltfp_sub)

sum tfp*
    
   
/* 4. Markdown estimation  
-----------------------------------------------------------------*/

// Revenue shares
 
// Markups and markdowns
 
gen md_sub = (beta_m_sub/alphaM)/(beta_l_sub/alphaL)
gen lmd_sub  = log(md_sub)
gen mu_sub = beta_l_sub/alphaL
gen lmu_sub = log(mu_sub)
 
sum md_sub, d
sum mu_sub, d
 
 
// Markdown moments: save results for table

/* 4. Consolidation treatment effects
-----------------------------------------*/

// Treatment effects - baseline

foreach mod in "sub"  {  
foreach var in "md" "tfp"   {
capture: areg l`var'_`mod' treat02_dq6  post02   yr  if dumobs==1  ,   absorb(fid) r 
capture: gen th_l`var'_`mod'=_b[treat02_dq`m']
capture: local r2 = e(r2)
capture: local r2_`var'`mod' = substr("`r2'",1,4)
capture: local N_`var'`mod' = e(N)
}
}

// save results for tables

gen th =.
foreach mod in "sub"   {  
foreach var in "lmd" "ltfp"   {
capture: 	replace th = th_`var'_`mod' 
capture: estpost su th
capture: est store th_`var'_dq6
}
}


sum beta* md* th*
drop th
 
* Store all estimates

/*
foreach var of varlist md* mu* {
egen `var'_p01 = pctile(`var'),p(01)
egen `var'_p99 = pctile(`var'),p(99)
}
*/
  
foreach var of varlist md*  mu* th* beta_l* beta_k* beta_m* scale*  {
egen av`var' = mean(`var')  
egen med`var' = median(`var')  
}
 

keep in 1/`B'

foreach var of varlist  beta_l* beta_k* beta_m*  th* scale*     {
 mkmat av`var', matrix(av`var')
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration in matrix	
}

  
foreach var of varlist  md* mu* {
 mkmat av`var' , matrix(av`var') 
 mkmat med`var' , matrix(med`var') 
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration in matrix
 matrix m_`var'[`b',1] = med`var'[1,1]			// store average markdown for this bootstrap iteration in matrix
}
 
restore			// end bootstrapping loop here

}


** Store estimates from each bootstrapping iteration in the matrices

* Production and input supply model

foreach mod  in "sub"    {
foreach coef in "beta_l" "beta_k"  "scale"   {
 svmat _`coef'_`mod'  
}
}

foreach mod  in "sub"  {
foreach coef in "beta_m"       {
 svmat _`coef'_`mod'  
}
}

 
foreach mod  in "sub"   {
foreach coef in "md" "mu" "th_lmd" "th_ltfp" {
 svmat _`coef'_`mod' 
 svmat  m_`coef'_`mod'  
}
}

keep in 1/`B'

save ./tempfiles/estimates_bs, replace
 
use ./tempfiles/estimates_bs, clear
 
sum _md*, d
sum _th*, d

** Standard errors for table 2
  
* Production function
   
foreach mod in "sub" {
egen bl = sd(_beta_l_`mod')
egen bk = sd(_beta_k_`mod')
egen bm = sd(_beta_m_`mod')
egen scale = sd(_scale_`mod')
estpost su bl bk  bm scale 
est store pf_`mod'_se
drop bl bk  bm  scale 
}
 
* Markdowns   
drop  m

foreach var in "mu" "md"   {
foreach mod in "sub"   {
egen a   = sd(_`var'_`mod') 
egen m   = sd(m_`var'_`mod')  
estpost su a m  
est store `var'_`mod'_se
drop a m 
}
}

** Standard errors for table 3

* Markdowns and productivity
 
foreach mod in "sub" { 
foreach var in "lmd" "ltfp"   {
egen th = sd(_th_`var'_`mod')
estpost su th 
est store th_`var'_`mod'_se
drop th
}
} 
 