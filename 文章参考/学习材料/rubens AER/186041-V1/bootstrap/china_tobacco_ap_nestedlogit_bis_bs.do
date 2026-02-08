/*	Market Structure, Oligopsony Power, and Productivity
			(Michael Rubens, UCLA)

			- NESTED LOGIT: BOOTSTRAPPING without tfp iv -
========================================================*/

cd "$station"
set more off
 
local B = $B      // # bootstrap iterations
local M = max(10,`B')

set matsize `M'

use ./Data/china_tobacco_data, clear
  
xtset fid yr
gen const = 1
  
/* 0. Make vectors to store coefficient estimates
------------------------------------------------*/

* Matrices to store estimates

foreach model in "nl" "tris"  {
foreach coef in "m" "sx" "x" "uw" "t1" "t2" "yr" "p" "d1" "d2"  {
matrix _gamma_`coef'_`model'_dq6 = J(`B', 1, 0)
}
matrix _sigma_`model'_dq6 = J(`B', 1, 0)
matrix _md_`model'_dq6 = J(`B', 1, 0)
matrix m_md_`model'_dq6 = J(`B', 1, 0)
matrix _mu_`model'_dq6 = J(`B', 1, 0)
matrix m_mu_`model'_dq6 = J(`B', 1, 0)
matrix _th_lmd_`model'_dq6 = J(`B', 1, 0)
matrix _th_lmu_`model'_dq6 = J(`B', 1, 0)
}
  
save ./tempfiles/data_pf_bb, replace		// dataset to estimate leontief bb

// Start bootstrapping iteration
 
forvalues b = 1/`B' {
preserve
use ./tempfiles/data_pf_bb, clear
set seed `b'
bsample, cluster(fid) idcluster(idb)  	// block bootstrap: resample entire firm time series.
replace fid = idb

di "iteration " `b'
   
/* 1. Production function
---------------------------*/

xtset fid yr
foreach var of varlist lq lk lemp treat_dq4 treat02_dq4 post02 luw lp lm{
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

/* 2. Input supply function
----------------------------*/
  
global share = 0.117647  	 

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

gen nfarm_f = q*$share
sum nfarm_f, d	// 49,268 farmers on average, 21,176 at the median.


// Weather shocks as additional instruments  
  
xtset fid yr
 reg lpm L.maxtemp  L.rain
gen lmaxtemp = log(maxtemp)
gen lrain = log(rain)
gen lavgmaxtemp = log(avgmaxtemp)
reg pm L.lmaxtemp  L.lrain  

sum maxtemp lrain mintemp
reg maxtemp  i.zip4id i.yr

forvalues m = 2(2)6 {
foreach var of varlist tfp_bb {
bys dq`m'id yr: egen `var'_dq`m' = sum(`var')
gen `var'_ot_dq`m' = `var'_dq`m'-`var'
gen l`var'_ot_dq`m' = log(`var'_ot_dq`m')
}
}

save ./tempfiles/datatemp_nl, replace

drop if rain==. | maxtemp==. |mintemp==. |sunshine==.
collapse rain maxtemp mintemp sunshine, by(dq6id dq4id dq2id yr)
gen open = 1
bys dq2id yr: egen n_dq2 = sum(open)
bys dq4id yr: egen n_dq4 = sum(open)

foreach var of varlist  rain maxtemp mintemp sunshine {
bys dq4id yr: egen `var'_dq4 = sum(`var')
gen `var'_dq4_ot = `var'_dq4-`var'
gen av_`var'_dq4_ot = `var'_dq4_ot/n_dq4

bys dq2id yr: egen `var'_dq2 = sum(`var')
gen `var'_dq2_ot = `var'_dq2-`var'_dq4
gen av_`var'_dq2_ot = `var'_dq2_ot/n_dq2
}
keep *ot dq* yr
save ./tempfiles/blp_inst, replace

use ./tempfiles/datatemp_nl, clear

merge m:1 dq6id dq4id dq2id yr using ./tempfiles/blp_inst
drop _merge
 
xtset fid yr

tab typeid, gen(dtype)

forvalue m = 2(2)6{ 
bys dq6 yr: egen p_dq`m' = sum(p)
gen pot_dq`m' = p_dq`m'-p
gen lpot_dq`m' = log(pot_dq`m')
}
 
drop *uw_* 
bys dq6id yr: egen n_dq6 = sum(open)
bys dq4id yr: egen n_dq4 = sum(open)
bys dq2id yr: egen n_dq2 = sum(open)

drop tfp_bb_dq2  tfp_bb_dq4 tfp_bb_dq6
foreach var of varlist uw tfp_bb {
bys dq2id yr: egen `var'_dq2 = sum(`var')
bys dq4id yr: egen `var'_dq4 = sum(`var')
bys dq6id yr: egen `var'_dq6 = sum(`var')

gen `var'_dq4_ot = `var'_dq4-`var'_dq6
gen av_`var'_dq4_ot = `var'_dq4_ot/n_dq4

gen `var'_dq2_ot = `var'_dq2-`var'_dq4
gen av_`var'_dq2_ot = `var'_dq2_ot/n_dq2

gen `var'_dq6_ot = `var'_dq6-`var' 
gen av_`var'_dq6_ot = `var'_dq6_ot/n_dq6
}
 
xtset fid yr

// Input supply model

bys dq6id yr: egen nf_dq6 = sum(open)	// number of manufacturers in each county
tab nf_dq6
 
** nested logit

local model = "bb" 
local m = 6			// market = county

ivregress 2sls lhs_dq`m' (pm   lqshare_nest_dq`m'  =  nf_dq6 av_mintemp_dq4_ot av_mintemp_dq2_ot  av_maxtemp_dq4_ot  av_maxtemp_dq2_ot av_rain_dq4_ot  av_rain_dq2_ot ///
  tfp_bb_ot_dq6       ) lrain  luw dexp pctexp  mintemp  maxtemp  yr   lp  dhs1 dhs2 dtype1 dtype2 i.dq2id   

 
gen gamma_m_nl_dq`m' = _b[pm]
gen gamma_x_nl_dq`m' = _b[dexp]
gen gamma_sx_nl_dq`m' = _b[pctexp]
gen gamma_uw_nl_dq`m' = _b[luw]
gen gamma_t1_nl_dq`m' = _b[dtype1]
gen gamma_t2_nl_dq`m' = _b[dtype2]
gen gamma_yr_nl_dq`m' = _b[yr]
gen gamma_p_nl_dq`m' = _b[lp]
gen gamma_d1_nl_dq`m' = _b[dhs1]
gen gamma_d2_nl_dq`m' = _b[dhs2]

gen sigma_nl_dq`m' = _b[lqshare_nest_dq`m'] 
gen supelast_nl_dq`m' = gamma_m_nl_dq`m'*pm*((1/(1-sigma_nl_dq`m')) - (sigma_nl_dq`m'/(1-sigma_nl_dq`m'))*(qshare_nest_dq`m') -qshare_dq`m')
gen md_nl_dq`m' = 1/supelast_nl_dq`m'+1
gen lmd_nl_dq`m' = log(md_nl_dq`m')
 
 * Alternative outside option: only switch to non-agricultural occupations

 gen popnonag = pop - popag

 forvalues m = 6(2)6 {
*bys dq`m'id yr: egen pop_lab_dq`m' = sum(pop_lab)
*replace pop_lab_dq`m' = poptab_dq`m' if poptab_dq`m'>pop_lab_dq`m'
gen qsharetris_dq`m' = q*$share/popnonag
gen lqsharetris_dq`m' = log(qsharetris_dq`m')
gen qsharetris_nest_dq`m' = q*$share/poptab_dq`m'
gen lqsharetris_nest_dq`m' = log(qsharetris_nest_dq`m')
gen ootris_dq`m' = (popnonag-poptab_dq`m')/popnonag
gen lootris_dq`m' =  log(ootris_dq`m')
gen lhstris_dq`m' = lqsharetris_dq`m' - lootris_dq`m'	
}

local m = 6
ivregress 2sls lhstris_dq`m' (pm  lqsharetris_nest_dq6  =  nf_dq6     av_mintemp_dq4_ot av_mintemp_dq2_ot  av_maxtemp_dq4_ot  av_maxtemp_dq2_ot av_rain_dq4_ot  av_rain_dq2_ot ///
  tfp_bb_ot_dq6     )  lrain luw dexp pctexp   mintemp  maxtemp  yr   lp  dhs* dtype1 dtype2 i.dq2id 
 
gen gamma_m_tris_dq`m' = _b[pm]
gen gamma_x_tris_dq`m' = _b[dexp]
gen gamma_sx_tris_dq`m' = _b[pctexp]
gen gamma_uw_tris_dq`m' = _b[luw]
gen gamma_t1_tris_dq`m' = _b[dtype1]
gen gamma_t2_tris_dq`m' = _b[dtype2]
gen gamma_yr_tris_dq`m' = _b[yr]
gen gamma_p_tris_dq`m' = _b[lp]
gen gamma_d1_tris_dq`m' = _b[dhs1]
gen gamma_d2_tris_dq`m' = _b[dhs2]

gen sigma_tris_dq`m' = _b[lqsharetris_nest_dq`m'] 
gen supelast_tris_dq`m' = gamma_m_tris_dq`m'*pm*((1/(1-sigma_tris_dq`m')) - (sigma_tris_dq`m'/(1-sigma_tris_dq`m'))*(qsharetris_nest_dq`m') -qsharetris_dq`m')
gen md_tris_dq`m' = 1/supelast_tris_dq`m'+1
gen lmd_tris_dq`m' = log(md_tris_dq`m')
  
/* 3. Markup estimation
--------------------------*/
// Calculate markups

gen alphaM = m/rev
gen alphaL = w/rev

gen dumobs =  lq~=.  & alphaM~=.& alphaL~=. & lemp~=.  & lk~=.



foreach model in "nl" "tris"  {
gen muL_`model' = beta_l_bb/alphaL
forvalues m = 6(2)6 {
gen mu_`model'_dq`m' = (1/muL_`model' + alphaM*md_`model'_dq`m') ^(-1)
gen lmu_`model'_dq`m' = log(mu_`model'_dq`m')
drop muL_`model'
}
}

 

bys yr: egen empyr = sum(emp)
gen sempyr = emp/empyr
foreach model in "nl" "tris"  {
gen smd_`model'_dq6 = md_`model'_dq6 * sempyr 
bys yr: egen agmd_`model'_dq6 = sum(smd_`model'_dq6)  
gen smu_`model'_dq6 = mu_`model'_dq6 * sempyr 
bys yr: egen agmu_`model'_dq6 = sum(smu_`model'_dq6)  
}  

 
// Summary statistics on markups and markdowns

  
 
/* 4. Consolidation treatment effects
-----------------------------------------*/

// Treatment effects - baseline

foreach mod in   "nl" "tris" {
forvalues m = 6(2)6 {
gen ltfp_`mod'_dq`m' = ltfp_bb
}
}

forvalues m = 6(2)6 {
foreach mod in   "nl" "tris" {
foreach var in "md" "mu"   {
areg l`var'_`mod'_dq`m' treat02_dq`m'  post02   yr if dumobs==1 ,   absorb(fid) r 
gen th_l`var'_`mod'_dq`m'=_b[treat02_dq`m']
}
}
} 

* Markdown and markup moments
 foreach var in "md_tris"   "md_nl" "mu_tris" "mu_nl"  {
egen _`var' = mean(`var'_dq6)
egen m_`var' = median(`var'_dq6)
}
 
* Store all estimates
 
foreach var of varlist md*  mu*  {
gen av`var' = ag`var'   
egen med`var' = median(`var')  
}

foreach var of varlist  th*  gamma* sigma*  {
egen av`var' = mean(`var')   
egen med`var' = median(`var')  
} 

keep in 1/`B'

foreach var of varlist  md* mu*   {
 mkmat av`var', matrix(av`var')
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration  
 mkmat med`var', matrix(med`var')
 matrix m_`var'[`b',1] = med`var'[1,1]			// store average markdown for this bootstrap iteration  
 }

 foreach var of varlist    th*  gamma*  sigma*   {
 mkmat av`var', matrix(av`var')
 matrix _`var'[`b',1] = av`var'[1,1]			// store average markdown for this bootstrap iteration  
 }
  
  
restore			// end bootstrapping loop here
}


** Store estimates from each bootstrapping iteration in the matrices

* Production and input supply model


foreach model in "nl" "tris"  {
foreach coef in "m" "sx" "x" "uw" "t1" "t2" "yr" "p" "d1" "d2"  {
svmat _gamma_`coef'_`model'_dq6  
}
svmat _sigma_`model'_dq6  
svmat _md_`model'_dq6  
svmat m_md_`model'_dq6  
svmat _mu_`model'_dq6  
svmat m_mu_`model'_dq6  
svmat _th_lmd_`model'_dq6  
svmat _th_lmu_`model'_dq6  
}

 
keep in 1/`B'

save ./tempfiles/estimates_bs, replace
use ./tempfiles/estimates_bs, clear

sum _th*
 
sum _md*, d
sum m_mu*, d
sum _gamma*, d

 
** Standard errors for table 2
  
* Supply function
 
foreach model in "nl" "tris" {
foreach coef in "m" "sx" "x" "uw" "t1" "t2" "yr" "p" /*"d1" "d2"*/  {
egen gamma_`coef'  = sd(_gamma_`coef'_`model')
}
egen sigma  = sd(_sigma_`model')

estpost su gamma_m  sigma gamma_sx  gamma_x  gamma_uw  gamma_t1 ///
gamma_t2  gamma_yr  gamma_p /* gamma_d1 gamma_d2 */
est store leafsup_`model'_se
drop gamma_m  sigma gamma_sx  gamma_x  gamma_uw  gamma_t1 gamma_t2  gamma_yr  gamma_p  /*gamma_d1 gamma_d2 */
}


sum _md_nl_dq6
sum m_mu_nl_dq6

 
* Markdowns and markups 

foreach var in "mu" "md" {
forvalues m = 6(2)6 {
foreach model in "nl" "tris" {

egen a_`var' = pctile(_`var'_`model'_dq`m'), p(5)
egen m_`var' = pctile(m_`var'_`model'_dq`m'), p(5)
estpost su a_`var' m_`var' 
est store `var'_`model'_dq`m'_p5
global a_`var'_`model'_p5 = a_`var'
global m_`var'_`model'_p5 = m_`var'
drop a_`var' m_`var'  

egen a_`var' = pctile(_`var'_`model'_dq`m'), p(10)
egen m_`var' = pctile(m_`var'_`model'_dq`m'), p(10)
estpost su a_`var' m_`var' 
est store `var'_`model'_dq`m'_p10
global a_`var'_`model'_p10 = a_`var'
global m_`var'_`model'_p10 = m_`var'
drop a_`var' m_`var'  

egen a_`var' = pctile(_`var'_`model'_dq`m'), p(90)
egen m_`var' = pctile(m_`var'_`model'_dq`m'), p(90)
global a_`var'_`model'_p90 = a_`var' 
global m_`var'_`model'_p90 = m_`var' 
estpost su a_`var'  m_`var' 
est store `var'_`model'_dq`m'_p90
drop a_`var' m_`var'  

egen a_`var' = pctile(_`var'_`model'_dq`m'), p(95)
egen m_`var' = pctile(m_`var'_`model'_dq`m'), p(95)
global a_`var'_`model'_p95 = a_`var' 
global m_`var'_`model'_p95 = m_`var' 
estpost su a_`var'  m_`var' 
est store `var'_`model'_dq`m'_p95
drop a_`var' m_`var'  

egen a_`var'  = sd(_`var'_`model'_dq`m') 
egen m_`var'  = sd(m_`var'_`model'_dq`m')  
estpost su a_`var' m_`var'  
est store `var'_`model'_dq`m'_se
drop a_`var' m_`var' 
}
}
}

di  `a_md_tris_p5'


** Standard errors for table 3

* Treatment effects
 
 forvalues m = 6(2)6 {
 foreach model in "nl" "tris" {
 foreach var in "lmd" "lmu"   {
egen th = sd(_th_`var'_`model'_dq`m')
estpost su th 
est store th_`var'_`model'_se
drop th
}
}
}

 