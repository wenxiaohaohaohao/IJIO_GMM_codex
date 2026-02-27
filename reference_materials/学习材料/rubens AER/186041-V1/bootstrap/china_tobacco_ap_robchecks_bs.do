/*	Ownership consolidation and buying power: evidence from Chinese tobacco
						(Michael Rubens, KU Leuven)

				 - ROBUSTNESS CHECKS: BOOTSTRAPPING -
============================================================================*/


cd "$station"
set more off

use ./Data/china_tobacco_data, clear
xtset fid yr
  
/* Make vectors to store coefficient estimates
------------------------------------------------*/
  
local B = $B		// number of bootstrap iterations
set more off

forvalues m = 2(2)6 {
foreach var in "md"   "tfp" {
foreach tr in   "under100K"   "bb"{
matrix _th_`var'_`tr' = J(`B', 1, 0)
}
}
}

foreach model in "bb"    {
foreach coef in "th_lmd"    "th_ltfp"     {
forvalues m = 2(2)6 {
matrix _`coef'_`model'_dq`m' = J(`B', 1, 0)
matrix m_`coef'_`model'_dq`m' = J(`B', 1, 0)
}
}
}
    
foreach model in   "tl"     "lap"{
foreach coef in "md" "mu" "th_lmd"    "th_ltfp"  {
matrix _`coef'_`model'  = J(`B', 1, 0)
matrix m_`coef'_`model'= J(`B', 1, 0)
}
}
 
foreach model in   "tl"   "lap"  {
foreach coef in "beta_l" "beta_k"   "scale" {
matrix _`coef'_`model' = J(`B', 1, 0)
}
}

forvalues m = 1(1)3 {
foreach coef in "md_rob" "th_rob"  {
matrix _`coef'`m' = J(`B', 1, 0)
}
}
 
 
foreach coef in "bmd1" "bmd2" "bmd3"  {
matrix _`coef'= J(`B', 1, 0)
}
  

save ./tempfiles/data_ap, replace		 

*local b = 1
forvalues b = 1/`B' {
preserve
use ./tempfiles/data_ap, clear
set seed `b'
bsample, cluster(fid) idcluster(idb)  	// block bootstrap: resample entire firm time series.
replace fid = idb

di "iteration " `b'
 
 gen alphaL = w/rev
gen alphaM = m/rev
 gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.


/* 1. Production function
------------------------------------------------*/

/* Baseline spec.   */

xtset fid yr
foreach var of varlist lq lk lemp treat_dq6 treat02_dq6 post02 luw lp lm{
gen `var'_lag = L.`var'		// make lagged variables
} 

gmm (lq - {rho}*L.lq - ({bk})*(lk-{rho}*L.lk) - {bl}*(lemp - {rho}*L.lemp)  - {bp}*(lp - {rho}*L.lp) ///
 - {bc1}*(treat02_dq6 - {rho}*L.treat02_dq6) - {bc2}*(treat_dq6 - {rho}*L.treat_dq6)- {bc3}*(post02 - {rho}*L.post02)- {bw}*(luw - {rho}*L.luw)  - {c}*(1-{rho}) )   , ///
inst(lk   luw lp    L.lemp    L.lk L.lp   L.luw treat_dq6 treat02_dq6 post02 )    
 
matrix pfest_bb = e(b)
local N_pf_bb= e(N)

mat bb_coef = e(b)
mat bb_se = e(V)
mat list bb_se
gen beta_k_bb = pfest_bb[1,2]
gen beta_l_bb = pfest_bb[1,3]
gen beta_p_bb = pfest_bb[1,4]
gen beta_c1_bb = pfest_bb[1,5]
gen beta_c2_bb = pfest_bb[1,6]
gen beta_c3_bb = pfest_bb[1,7]
gen beta_uw_bb = pfest_bb[1,8]
gen beta_c_bb = pfest_bb[1,9]
gen scale_bb = beta_k_bb + beta_l_bb + beta_c1_bb + beta_c2_bb + beta_c3_bb

     
gen ltfp_bb = lq - beta_l_bb*lemp - beta_k_bb*lk   - beta_c_bb	// make tfp residual
gen tfp_bb = exp(ltfp_bb)

 
 
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

gen beta_l_tl = tl_l + 2*tl_ll *lemp + tl_lk *lk
gen beta_k_tl = tl_k + 2*tl_kk *lk + tl_lk *lemp
gen scale_tl = beta_l_tl+beta_k_tl

  /* 3. Model with labor-augmenting technological change 
--------------------------------------------------------*/
  
gen inv = D.k  
gen cs_l = w/(w +inv)
gen cs_k = inv/(w+inv)
bys yr: egen beta_l_lap = median(cs_l)
bys yr: egen beta_k_lap = median(cs_k)   
   gen scale_lap = 1
 
gen ltfp_lap = lq - beta_l_lap*lemp - beta_k_lap*lk   		// make tfp residual
gen tfp_lap = exp(ltfp_lap)
/*  Calculate productivity residuals */
 

gen ltfp_tl = lq - tl_l*lemp - tl_k*lk - tl_ll*lemp^2 - tl_kk*lk^2  - tl_lk*lemp*lk
gen tfp_tl = exp(ltfp_tl)

corr tfp*
corr ltfp*
   
 
foreach mod in "tl" "bb"  "lap"{
 
gen md_`mod' = (1/alphaM)*(1-alphaL/beta_l_`mod')
gen lmd_`mod'  = log(md_`mod')
} 

sum md*, d
 

 * Different markup calibrations
 
gen md_rob1 = (1/alphaM)*(1/(0.644)-alphaL/beta_l_bb)
gen md_rob2 = (1/alphaM)*(1/(1 )-alphaL/beta_l_bb)
gen md_rob3 = (1/alphaM)*(1/(1.502)-alphaL/beta_l_bb)



/* 3. Treatment effects 
--------------------------*/


/* Different production models */

foreach model in   "tl"   "lap"{
local m = 6
areg lmd_`model'  treat02_dq`m' /*treat_dq`m'*/  post02 yr  if dumobs==1 , absorb(fid) r 
gen th_lmd_`model' = _b[treat02_dq`m']
areg ltfp_`model' treat02_dq`m' /*treat_dq`m'*/ post02 yr if dumobs==1, absorb(fid) r 
gen th_ltfp_`model' = _b[treat02_dq`m']
}
 


/* Different market definitions */

foreach model in "bb" {
forvalues m = 2(2)6 {
areg lmd_`model'  treat02_dq`m' post02  yr if dumobs==1 , absorb(fid) r 
gen th_lmd_`model'_dq`m'  = _b[treat02_dq`m']
areg ltfp_`model' treat02_dq`m' post02 yr if dumobs==1, absorb(fid) r 
gen th_ltfp_`model'_dq`m'_dq`m' = _b[treat02_dq`m']
}
} 

     
  
// Drop  firms under 100K (except nonSOEs)

forvalues m = 6(2)6 {
foreach var in  "md" "tfp" {
areg l`var'_bb  treat02_dq`m'  post02 yr  if dumobs==1  | typeid~=1 & under100K==0, absorb(fid) r 
gen th_`var'_under100K  = _b[treat02_dq`m']
}
}  
 

forvalues m = 6(2)6 {
foreach var in  "md" "tfp"{
foreach tr in  "under100K"     {
egen avth_`var'_`tr'   = mean(th_`var'_`tr') 
}
}
}
  
// Different markup calibrations

forvalues m = 1/3 {
gen lmd_rob`m' = log(md_rob`m')
areg lmd_rob`m' treat02_dq6  post02   yr  if dumobs==1 ,   absorb(fid) r 
gen th_rob`m' = _b[treat02_dq6]
}


* Quality

*gen lmd_bb = log(md_bb)

merge m:1 FRDM yr using ./data/quality/data_quality
drop if _merge==2
drop _merge
  
/* i. treatment effects */

drop ssub
gen ssub = sub/rev

/* iii. markdown treatment effects */
 
areg lmd_bb treat02_dq6 treat_dq6 post02 i.yr if dsub ~=.& dumobs==1, absorb(fid)
gen bmd1 = _b[treat02_dq6]

areg lmd_bb treat02_dq6 treat_dq6 post02 i.yr dsub if dsub ~=.& dumobs==1, absorb(fid)
gen bmd2 = _b[treat02_dq6]

areg lmd_bb treat02_dq6 treat_dq6 post02 i.yr dsub ssub if dsub ~=.& dumobs==1, absorb(fid)
gen bmd3 = _b[treat02_dq6]

/*
foreach dep in "md" "mu" {
forvalues m = 4(2)4 {
foreach tr in "maxnunder100K" "lpctmig" "luerate" "lpctedu_nosch" {
egen avth_`dep'_`tr'_dq`m' = mean(th_`dep'_`tr'_dq`m')
} 
}
}
*/
 
* Store all estimates
  
 foreach model in    "tl" "bb"    "lap" {
 foreach var of varlist *`model'*  {
 egen av`var' = mean(`var')
   egen med`var' = median(`var')
}
}

foreach coef in "bmd1" "bmd2" "bmd3" "md_rob1" "md_rob2" "md_rob3" "th_rob1" "th_rob2" "th_rob3" {
egen av`coef' = mean(`coef') if dumobs==1
}


 
//egen avgamma_l = mean(gamma_l)

keep in 1/`B'

* Consolidation treatment effects
  

foreach coef in "bmd1" "bmd2" "bmd3"  {
mkmat av`coef', matrix(av`coef')
matrix _`coef'[`b',1] = av`coef'[1,1]
}


foreach mod in   "tl" "lap" {
foreach var in "beta_l" "beta_k" "scale"   {
 mkmat av`var'_`mod', matrix(av`var'_`mod')
  matrix _`var'_`mod'[`b',1] = av`var'_`mod'[1,1]			// store average markdown for this bootstrap iteration in matrix	
}
}

forvalues m = 1(1)3 {
foreach coef in "md_rob" "th_rob"  {
mkmat av`coef'`m' , matrix(av`coef'`m')
  matrix _`coef'`m'[`b',1] = av`coef'`m'[1,1]		  
 }
}



foreach var in     "md_tl"  "md_lap"    {
 mkmat av`var', matrix(av`var')
 mkmat med`var', matrix(med`var')
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration in matrix
 matrix m_`var'[`b',1] = med`var'[1,1]			// store average markdown for this bootstrap iteration in matrix
}

forvalues m = 2(2)6 {
foreach var in "lmd" "ltfp"{
foreach tr in   "bb"  {
 mkmat avth_`var'_`tr'_dq`m'  , matrix(avth_`var'_`tr'_dq`m')
 matrix _th_`var'_`tr'_dq`m'[`b',1] = avth_`var'_`tr'_dq`m'[1,1]			// store average markdown for this bootstrap iteration in matrix
}
}
}

foreach var in "lmd" "ltfp"{
foreach tr in     "tl" "lap" {
 mkmat avth_`var'_`tr'   , matrix(avth_`var'_`tr'_dq`m')
 matrix _th_`var'_`tr'[`b',1] = avth_`var'_`tr'_dq`m'[1,1]			// store average markdown for this bootstrap iteration in matrix
}
}

forvalues m = 6(2)6 {
foreach var in  "md" "tfp"{
foreach tr in  "under100K"  {
 mkmat avth_`var'_`tr'   , matrix(avth_`var'_`tr')
 matrix _th_`var'_`tr' [`b',1] = avth_`var'_`tr'[1,1]			// store average markdown for this bootstrap iteration in matrix
}
}
}
 

/*
foreach dep in "md" "mu" {
forvalues m = 4(2)4 {
foreach tr in "maxnunder100K" "lpctmig" "luerate" "lpctedu_nosch" {
mkmat avth_`dep'_`tr'_dq`m'  , matrix(avth_`dep'_`tr'_dq`m')
matrix _th_`dep'_`tr'_dq`m'[`b',1] = avth_`dep'_`tr'_dq`m'[1,1]			// store average markdown for this bootstrap iteration in matrix
} 
}
}
*/
 
restore			// end bootstrapping loop here
}

** Store estimates from each bootstrapping iteration in the matrices
/*
 foreach model in    "tl"  "end" {
 foreach var of varlist *`model'*  {
 egen av`var' = mean(`var')
 egen med`var' = median(`var')
}
}
*/

//egen avgamma_l = mean(gamma_l)

keep in 1/`B'

* Consolidation treatment effects
 
foreach mod in "tl"  "lap" {
foreach var in "beta_l" "beta_k" "scale"  {
svmat _`var'_`mod' 
}
}

forvalues m = 1/3 {
foreach coef in "md_rob" "th_rob"  {
svmat _`coef'`m' 
}
}
 
foreach coef in "bmd1" "bmd2" "bmd3"  {
svmat _`coef'
}
 
foreach var in     "md_tl"   "md_lap"    {
svmat _`var' 		// store average markdown for this bootstrap iteration in matrix
svmat m_`var' 			// store average markdown for this bootstrap iteration in matrix
}

 
foreach var in "md" "tfp"{
foreach tr in    "tl" "lap" {
svmat _th_l`var'_`tr'  		// store average markdown for this bootstrap iteration in matrix
}
}
 

forvalues m = 2(2)6 {
foreach var in "md" "tfp"{
foreach tr in   "bb" {
svmat _th_l`var'_`tr'_dq`m' 		// store average markdown for this bootstrap iteration in matrix
}
}
}


forvalues m = 6(2)6 {
foreach var in  "md" "tfp"{
foreach tr in  "under100K"  {
svmat _th_`var'_`tr' 		// store average markdown for this bootstrap iteration in matrix
}
}
}

  
keep in 1/`B'

sum _th*

 
   
 
** Store estimates for tables
 
* Production functions
 
foreach mod in "tl" "lap" {
foreach var in "k" "l"   {
egen b`var' = sd(_beta_`var'_`mod')
}
egen scale =  sd(_scale_`mod')
estpost su bl bk scale
est store pf_`mod'_se
drop bl bk   scale
}

* Markups

foreach mod in "tl"    "lap" {
egen a_md = sd(_md_`mod')
egen m_md  = sd(m_md_`mod')
estpost su  a_md m_md 
est store md_`mod'_se
drop a_md m_md
}

* Treatment effects

foreach mod in   "tl"  "lap" {
foreach var in   "md" "tfp"   {
egen th_`var' = sd(_th_l`var'_`mod')
}
estpost su th_md  th_tfp  
est store th_`mod'_se
drop th_md   th_tfp  
}

* Diff. market definitions
foreach var in  "md" "tfp" {
forvalues m = 2(2)6 {
egen th_dq`m' = sd(_th_l`var'_bb_dq`m')
}
estpost su th_dq2 th_dq4 th_dq6
est store th_`var'_se
drop th_dq*
}

* different markup values

forvalues m = 1/3 {
egen rob`m' = sd(_md_rob`m')
}
estpost su rob1 rob2 rob3
est store md_rob_se
drop rob* 

forvalues m = 1/3 {
egen rob`m' = sd(_th_rob`m')
}
estpost su rob1 rob2 rob3
est store th_rob_se
drop rob* 


* Drop small firms

foreach var in  "md" "tfp" {
egen th_under100K = sd(_th_`var'_under100K)
estpost su th_under100K
est store th_`var'_under100K_se
drop th_under100K
} 

* Quality

forvalues m = 1/3 {
egen bmd = sd(_bmd`m')
estpost su bmd
est store bmd`m'_se
drop bmd
}
 



 

