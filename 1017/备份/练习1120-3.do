
clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"

local have_b0_mata 0                                                        

if ("$GROUP_NAME"=="") {
    di as err "ERROR: global GROUP_NAME is empty. Set it before calling this do-file."
    exit 3499
}
if ("$GROUP_NAME"!="G1_17_19" & "$GROUP_NAME"!="G2_39_41") {
    di as err "ERROR: invalid GROUP_NAME=[$GROUP_NAME]. Must be G1_17_19 or G2_39_41."
    exit 3499
}

local GROUPNAME "$GROUP_NAME"
di as txt "DBG: GROUP_NAME(global) = [$GROUP_NAME] ; GROUPNAME(local) = `GROUPNAME'"


use "junenewg_0902", clear



if ("`GROUPNAME'"=="G1_17_19") {
    keep if inlist(cic2,17,18,19)
}
else if ("`GROUPNAME'"=="G2_39_41") {
    keep if inlist(cic2,39,40,41)
}
else {
    di as err "Unknown GROUPNAME=`GROUPNAME'. Must be G1_17_19 or G2_39_41."
    exit 198
}


duplicates drop firmid year, force


capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,")
xtset firmid year



gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

drop if domesticint <= 0
drop if 营业收入合计千元 < 40

gen double R = 工业总产值_当年价格千元 * 1000 / e

rename 固定资产合计千元 K
drop if K < 30
rename 全部从业人员年平均人数人 L
replace L = 年末从业人员合计人 if year==2003
drop if L < 8

rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

gen double WL = 应付工资薪酬总额千元 * 1000 / e


gen firmcat = . 


replace firmcat = 1 if firmtype == 1


replace firmcat = 2 if inlist(firmtype, 2, 3, 4)


replace firmcat = 3 if missing(firmcat)


label define firmcatlbl 1 "国企" 2 "外企" 3 "私企", replace
label values firmcat firmcatlbl

capture drop firmcat_*
tab firmcat, gen(firmcat_)


tab firmcat



capture confirm variable firmtotalq
if !_rc rename firmtotalq X


merge m:1 year using "Brandt-Rawski investment deflator.dta", nogen
replace BR_deflator = 116.7 if year == 2007
drop if year < 2000

bysort firmid (year): gen double I = K - K[_n-1]
bysort firmid (year): replace I = K if _n == 1

bysort firmid (year): gen double inv0 = I
replace inv0 = 0 if missing(inv0)
forvalues v = 1/19 {
    bysort firmid (year): gen double inv`v' = I[_n-`v'] * (BR_deflator / BR_deflator[_n-`v']) if _n > `v'
    replace inv`v' = 0 if missing(inv`v')
}
gen double K_current = inv0
forvalues v = 1/19 {
    replace K_current = K_current + inv`v'
}
drop inv0-inv19
replace K = K_current

rename 工业中间投入合计千元 MI
rename 管理费用千元 Mana

gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0
capture ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen double lratiofs = lnR - lnM

gen ratio = importint/(domesticint+importint)


gen inputp = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF = importint/einputp

replace 开业成立时间年 = . if 开业成立时间年==0
gen age   = year - 开业成立时间年 + 1
drop if age<=0 | missing(age)
gen lnage = ln(age)

gen lnmana = ln(Mana)

gen  l  = ln(L)
gen  lsq = l*l 
gen double k  = ln(K)
gen  ksq = k*k  
gen double q  = ln(Q)
gen m = ln(delfateddomestic)        
gen double x  = ln(X)
gen double rev  = ln(R)
gen DWL=WL/L
gen wl=ln(DWL)

winsor2 k, cuts(1 99) by(cic2 year) replace
winsor2 l, cuts(1 99) by(cic2 year) replace
xtset firmid year

capture confirm variable pft
if !_rc rename pft pi
capture confirm variable foreignprice
if !_rc rename foreignprice WX
capture confirm variable WX
if !_rc gen double wx = ln(WX)


reg lratiofs k l wl x lnage lnmana i.firmcat i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2


reg rev c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmcat i.city i.year

predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "firststage.dta", replace

sort firmid year
isid firmid year, sort
di "✅ Data sorted and verified: unique firm-year combinations"


by firmid: gen gap = year - L.year


by firmid: gen seqblock = (gap != 1 | missing(gap))
by firmid: replace seqblock = sum(seqblock)


bys firmid seqblock: gen seg_len = _N


bys firmid: egen max_seg_len = max(seg_len)


keep if max_seg_len >= 2

drop gap seqblock seg_len max_seg_len


bys firmid: gen nobs_firm = _N
tab nobs_firm, missing
sum nobs_firm, detail
drop nobs_firm



isid firmid year, sort
xtset firmid year
gen double phi_lag = L.phi

gen double klag = L.k
gen double mlag = L.m
gen double xlag = L.x
gen double llag = L.l
gen double ksqlag = L.ksq
gen double lsqlag = L.lsq

gen double llagsq = llag^2
gen double klagsq = klag^2
gen double mlagsq = mlag^2
gen double xlagsq = xlag^2

gen double llagklag = llag*klag
gen double llagmlag = llag*mlag
gen double llagxlag = llag*xlag
gen double klagmlag = klag*mlag
gen double klagxlag = klag*xlag
gen double mlagxlag = mlag*xlag

gen double llag2 = L2.l

gen double llagk = llag*k
gen double mlagl = mlag*l
gen double mlagxlagk = mlagxlag*k
gen double xlagk = xlag*k
gen double mlagk = mlag*k
gen double mlagllag = mlag*llag
gen double llagxlagmlag = llagxlag*mlag
gen double xlagllag = xlag*llag
gen double xllagl = xlag*l

gen double lages   = L.es
gen double lages2q = L.es2q
gen double klages=k*lages

gen double kl = k*l
gen byte   const = 1

capture confirm variable const
if _rc gen byte const = 1
order firmid year, first



levelsof year, local(yrs)
local base : word 1 of `yrs'
quietly tab year, gen(Dy)
local j = 1
foreach y of local yrs {
    if `y' == `base' drop Dy`j'
    else               rename Dy`j' dy`y'
    local ++j
}



isid firmid year, sort
xtset firmid year

drop if missing(rev, l, k, phi, phi_lag, llag, klag, mlag, lsqlag, ksqlag, ///
    lsq, ksq, m, es, es2q, lages, lages2q, lnage, firmcat, lnmana, ///
    firmcat_2, firmcat_3, klages, mlagxlag)
	

capture drop OMEGA2 XI2              
gen double OMEGA2 = .                   
gen double XI2    = .           


mata:
mata clear
Wg     = J(0,0,.)
OMEGA2 = J(0,1,.)
XI2    = J(0,1,.)

void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init


    X      = st_data(., ("const","l","k","lsq","ksq","m","es","es2q"))
    X_lag  = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag","lages","lages2q"))


    string scalar g
    g = st_global("GROUP_NAME")
    if (g=="G1_17_19") {
        Z = st_data(., ("const","llag","k","mlag","klag","l","lsq","lages","klages"))
    }
    else if (g=="G2_39_41") {
        Z = st_data(., ("const","llag","k","mlag","klag","l","lages","llagklag","lsq","mlagk","klages","ksq"))
    }
    else {
        errprintf("Invalid GROUP_NAME = [%s]\n", g)
        _error(3499)
    }

   
    PHI      = st_data(., "phi")
    PHI_lag  = st_data(., "phi_lag")
    Y        = st_data(., "rev")
    C        = st_data(., "const")

 CONSOL  = st_data(., "lnage")

    real scalar use_b0
    use_b0 = strtoreal(st_local("have_b0_mata"))

    if (use_b0==1) {
        beta_init = st_matrix("b0")'
        if (cols(beta_init)!=cols(X)) beta_init = (invsym(X'X) * (X'Y))'
    }
    else {
        beta_init = (invsym(X'X) * (X'Y))'
    }
}


void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL

    real colvector OMEGA, OMEGA_lag, XI, gb, m
    real matrix POOL
    real scalar N


    OMEGA     = PHI     - X     * b'
    OMEGA_lag = PHI_lag - X_lag * b'


    if (cols(CONSOL) > 0) {
        POOL = (C, OMEGA_lag, CONSOL)
    }
    else {
        POOL = (C, OMEGA_lag)
    }
    gb = qrsolve(POOL, OMEGA)   
    XI = OMEGA - POOL * gb        


    N = rows(Z)
    m = quadcross(Z, XI) :/ N    


    crit = m' * m


}


void run_one_step()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init

    real scalar N, Kx, Kz
    real scalar S1, conv1, J, df, jp
    real rowvector b
    real colvector OMEGA2, OMEGA2_lag, XI2, gb, m
    real matrix POOL2


    st_numscalar("gmm_conv1", 0)
    st_numscalar("gmm_conv2", 1)
    st_numscalar("gmm_conv",  0)
    st_numscalar("J_unit",    .)
    st_numscalar("J_opt",     .)
    st_numscalar("J_df",      .)
    st_numscalar("J_p",       .)


    N  = rows(Z)
    Kx = cols(X)
    Kz = cols(Z)
    st_numscalar("Nobs", N)

    printf("\n>> [GMM-1step] N=%f, Kx=%f, Kz=%f\n", N, Kx, Kz)

    if (Kz < Kx) {
        errprintf("ERROR: Not enough instruments (Kz=%f < Kx=%f).\n", Kz, Kx)
        _error(3498)
    }


    S1 = optimize_init()
    optimize_init_evaluator(S1, &GMM_DL_weighted())
    optimize_init_evaluatortype(S1, "d0")
    optimize_init_which(S1, "min")
    optimize_init_params(S1, beta_init)
    optimize_init_technique(S1, "nm")

    optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.1))
    optimize_init_conv_maxiter(S1, 500)
    optimize_init_conv_ptol(S1, 1e-5)
    optimize_init_conv_vtol(S1, 1e-5)
    optimize_init_tracelevel(S1, "none")

    b    = optimize(S1)                    // 1 × Kx
    J    = optimize_result_value(S1)
    conv1 = optimize_result_converged(S1)

    printf("   [1-step GMM] J = %12.6f, converged = %f\n", J, conv1)

    st_numscalar("gmm_conv1", conv1)
    st_numscalar("gmm_conv",  conv1)


    OMEGA2     = PHI     - X     * b'
    OMEGA2_lag = PHI_lag - X_lag * b'

    if (cols(CONSOL) > 0) {
        POOL2 = (C, OMEGA2_lag, CONSOL)
    }
    else {
        POOL2 = (C, OMEGA2_lag)
    }
    gb  = qrsolve(POOL2, OMEGA2)
    XI2 = OMEGA2 - POOL2 * gb


    m = quadcross(Z, XI2) :/ N   


    J  = N * quadcross(m, m)
    df = Kz - Kx
    jp = .
    if (df > 0) jp = chi2tail(df, J)

    printf("\n>> [GMM-1step] J-stat : %12.4f  (df=%g, p=%6.4f)\n", J, df, jp)
    printf("   Converged (step1) : %f\n", conv1)


    st_matrix("beta_lin_step1", b')      
    st_matrix("beta_lin",        b')      
    st_matrix("g_b",             gb)      

    st_matrix("moments_unit",    m')
    st_matrix("moments_opt",     m')     

    st_numscalar("J_unit",   J)
    st_numscalar("J_opt",    J)         
    st_numscalar("J_df",     df)
    st_numscalar("J_p",      jp)

 
    st_store(., "OMEGA2", OMEGA2)
    st_store(., "XI2",    XI2)
}

end








program define gmm2step_once, rclass
    version 18
    syntax [, rep(integer 0)]

    

     mata: refresh_globals()
    if _rc {
        local rc_refresh = _rc
        di as err "ERROR in refresh_globals(): rc=`rc_refresh'"
        exit `rc_refresh'
    }
capture mata: run_one_step()
if _rc {
    local rc_mata = _rc
    di as err "ERROR in run_one_step(): rc=`rc_mata'"
    exit `rc_mata'
}


    

    capture confirm scalar gmm_conv
    if _rc {
        di as err "gmm_conv not returned"
        exit 498
    }
    
    if scalar(gmm_conv) != 1 {
        di as txt "WARNING: GMM did not fully converge (gmm_conv=`=scalar(gmm_conv)')"
    }
    

    capture confirm matrix beta_lin
    if _rc {
        di as err "beta_lin not returned"
        exit 498
    }
    
    matrix b = beta_lin
    return scalar b_c1   = b[1,1]
    return scalar b_l    = b[2,1]
    return scalar b_k    = b[3,1]
    return scalar b_lsq  = b[4,1]
    return scalar b_ksq  = b[5,1]
    return scalar b_m    = b[6,1]
    return scalar b_es   = b[7,1]
    return scalar b_essq = b[8,1]
    

    capture confirm matrix g_b
    if _rc {
        di as err "g_b not returned"
        exit 498
    }
    
    matrix gb = g_b
 
    return scalar b_lnage    = gb[9,1]
    return scalar b_firmcat_2 = gb[10,1]
    return scalar b_firmcat_3 = gb[11,1]
    

    capture confirm scalar J_opt
    if !_rc return scalar J_opt = scalar(J_opt)
    
    capture confirm scalar J_p
    if !_rc return scalar J_p = scalar(J_p)
    

    
    di as txt "Rep `rep': completed in `=r(t1)' sec. J_opt=`=scalar(J_opt)'"
end




  
capture matrix drop b0
di as text _n(2) "{hline 80}"
di as text "Running full-sample GMM to get starting values and point estimates"
di as text "{hline 80}"

local have_b0 0
mata: st_local("have_b0","`have_b0'")

capture noisily gmm2step_once
local rc = _rc

if (`rc'==430) {
    capture confirm scalar J_opt
    if (_rc==0 & scalar(J_opt) < 1e-8) {
        di as txt "Flat region; treat as converged because J_opt is tiny."
        scalar gmm_conv = 1
        local rc 0
    }
}

if (`rc'==0) {
    capture confirm scalar gmm_conv
    if (_rc==0 & scalar(gmm_conv)==1) {
        matrix b0 = beta_lin
        local have_b0_mata 1  
        di as text "Full-sample GMM converged. Using as starting point for bootstrap."
    }
    else {
        di as err "Full-sample GMM ran but did not converge; cannot save point estimates."
        exit 459
    }
}
else {
    di as err "Full-sample GMM failed (rc=`rc'): cannot save point estimates."
    exit 459
}
if (`rc' == 0) {

    capture matrix drop b0
    matrix b0 = beta_lin


    local have_b0_mata 1
}
else {
    di as error "WARNING: full-sample GMM failed (rc = `rc'), no b0 will be used."
    local have_b0_mata 0
}

local b_lnage_hat     = r(b_lnage)
local b_firmcat2_hat  = r(b_firmcat_2)
local b_firmcat3_hat  = r(b_firmcat_3)

capture drop omega_hat xi_hat
gen double omega_hat = OMEGA2
gen double xi_hat    = XI2


qui count if missing(omega_hat, xi_hat)
if r(N) > 0 {
    di as txt "WARNING: `r(N)' missing values in omega_hat/xi_hat"
}


preserve
    keep firmid year cic2 omega_hat xi_hat
    gen str10 group = "`GROUPNAME'"
    order group firmid year cic2 omega_hat xi_hat
    compress
    save "omega_xi_group_`GROUPNAME'.dta", replace
restore



quietly count
local Nobs = r(N)
preserve
    clear
    set obs 1
    gen group = "`GROUPNAME'"
    matrix b = beta_lin
    gen b_const = b[1,1]
    gen b_l     = b[2,1]
    gen b_k     = b[3,1]
    gen b_lsq   = b[4,1]
    gen b_ksq   = b[5,1]
    gen b_m     = b[6,1]
    gen b_es    = b[7,1]
    gen b_essq  = b[8,1]

    gen b_lnage     = `b_lnage_hat'
    gen b_firmcat_2 = `b_firmcat2_hat'
    gen b_firmcat_3 = `b_firmcat3_hat'
	
    gen J_unit  = J_unit
    gen J_opt   = J_opt
    gen J_df    = J_df
    gen J_p     = J_p
    gen N       = `Nobs'
    order group b_const b_l b_k b_lsq b_ksq b_m b_es b_essq ///
          b_lnage b_firmcat_2 b_firmcat_3 ///
          J_unit J_opt J_df J_p N
    compress
    save "gmm_point_group_`GROUPNAME'.dta", replace
restore



matrix list beta_lin_step1                                              
matrix list beta_lin                                                   
matrix list moments_unit                                               
matrix list moments_opt                                                 
scalar list J_unit J_opt J_df J_p gmm_conv                              
display as text "J_opt = " J_opt "  (df = " J_df ", p = " J_p ")"       




di as text _n(2) "{hline 80}"
di as text "Starting bootstrap estimation (clustered by firmid)"
di as text "{hline 80}"

tempname H
tempfile bootres
local failed = 0
local total_time = 0


set seed 20250830
local B = 2 


tempfile failures
postfile failures rep reason using "`failures'", replace

postfile `H' rep double(b_const b_l b_k b_lsq b_ksq b_m b_es b_essq b_lnage b_firmcat_2 b_firmcat_3 J_opt time) 
    using "`bootres'", replace

forvalues ro = 1/`B' {
    di as text _n "Bootstrap rep `ro'/`B'"
    
    preserve

        quietly bsample, cluster(firmid) idcluster(newfid)
        

        gen long orig_firmid = firmid
        replace firmid = newfid
        xtset firmid year
        

        by firmid: gen byte __T = _N
        keep if __T >= 2
        drop __T
        
        qui count
        local N_bs = r(N)
        di as text "  Sample size after keeping T>=2: `N_bs'"
        
        if (`N_bs' < 50) {
            di as txt "  WARNING: Very small sample (`N_bs' obs). May not converge."
        }
        
        capture noisily gmm2step_once, rep(`ro')
        local rc = _rc
        
        if (`rc' == 0) {

            capture confirm scalar gmm_conv
            if _rc {
                local reason "gmm_conv not returned"
                local rc 499
            }
            else if scalar(gmm_conv) != 1 {
                local reason "not converged (gmm_conv=`=scalar(gmm_conv)')"
                local rc 499
            }
        }
        else {
            local reason "gmm2step_once failed with rc=`rc'"
        }

        if (`rc' == 0 & scalar(gmm_conv) == 1) {
            post `H' (`ro') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_lsq)) (r(b_ksq)) (r(b_m)) ///
                   (r(b_es)) (r(b_essq)) (r(b_lnage)) (r(b_firmcat_2)) (r(b_firmcat_3)) ///
                   (r(J_opt)) (r(time))
            

            capture confirm matrix beta_lin
            if (_rc == 0) {
                matrix b0 = beta_lin
                local have_b0_mata 1
            }
            else {
                di as txt "  WARNING: beta_lin not available, cannot update starting point"
            }
            
            local total_time = `total_time' + r(time)
            di as result "  SUCCESS: rep `ro' converged in `=r(time)' sec"
        }
        else {
            local ++failed
            post failures (`ro') ("`reason'")
            di as error "  FAILED: rep `ro' - `reason'"
        }
    restore
}

postclose `H'
postclose failures

di as result _n(2) "Bootstrap completed:"
di as result "  Total reps: `B'"
di as result "  Successful: `=`B'-`failed''"
di as result "  Failed: `failed'"
di as result "  Avg time per rep: `=`total_time'/(`B'-`failed')' sec"


use "`failures'", clear
if _N > 0 {
    list, noobs
    save "bootstrap_failures_`GROUPNAME'.dta", replace
}


use "`bootres'", clear
if _N == 0 {
    di as err "No successful bootstrap replications. Cannot compute SEs."
    exit 430
}


qui summarize b_const, detail
local se_const = r(sd)
qui summarize b_l, detail
local se_l     = r(sd)
qui summarize b_k, detail
local se_k     = r(sd)
qui summarize b_lsq, detail
local se_lsq   = r(sd)
qui summarize b_ksq, detail
local se_ksq   = r(sd)
qui summarize b_m, detail
local se_m     = r(sd)
qui summarize b_es, detail
local se_es    = r(sd)
qui summarize b_essq, detail
local se_essq  = r(sd)
qui summarize b_lnage, detail
local se_lnage     = r(sd)
qui summarize b_firmcat_2, detail
local se_firmcat_2 = r(sd)
qui summarize b_firmcat_3, detail
local se_firmcat_3 = r(sd)


use "gmm_point_group_`GROUPNAME'.dta", clear
gen se_const = `se_const'
gen se_l     = `se_l'
gen se_k     = `se_k'
gen se_lsq   = `se_lsq'
gen se_ksq   = `se_ksq'
gen se_m     = `se_m'
gen se_es    = `se_es'
gen se_essq  = `se_essq'
gen se_lnage     = `se_lnage'
gen se_firmcat_2 = `se_firmcat_2'
gen se_firmcat_3 = `se_firmcat_3'
gen boot_reps = `=`B'-`failed''
gen avg_time = `=`total_time'/(`B'-`failed')'

replace J_df = scalar(J_df)
replace J_p = scalar(J_p)
order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq b_m se_m b_es se_es b_essq se_essq ///
      b_lnage se_lnage b_firmcat_2 se_firmcat_2 b_firmcat_3 se_firmcat_3 ///
      J_unit J_opt J_df J_p N boot_reps avg_time

compress
save "gmm_point_group_`GROUPNAME'.dta", replace



use "`bootres'", clear
compress
save "gmm_boot_group_`GROUPNAME'.dta", replace


di as res _n(2) "{hline 80}"
di as res "Done group `GROUPNAME'. Files written:"
di as res "  gmm_point_group_`GROUPNAME'.dta   (points + bootstrap SEs + diagnostics)"
di as res "  gmm_boot_group_`GROUPNAME'.dta    (draws)"
di as res "  omega_xi_group_`GROUPNAME'.dta   (firm-level residuals)"
if `failed' > 0 di as res "  bootstrap_failures_`GROUPNAME'.dta (failure reasons)"
di as res "{hline 80}"


local end_time = c(current_time)
display as text "INFO: Script finished at `end_time'"