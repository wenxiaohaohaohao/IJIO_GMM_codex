clear all
set more off
capture log close _all

local RUN_TAG "20260224_042843"
global ROOT "."
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work/run_`RUN_TAG'"
global RES_DATA "$ROOT/results/data/run_`RUN_TAG'"
global RES_LOG "$ROOT/results/logs/run_`RUN_TAG'"

capture mkdir "$RES_DATA"
capture mkdir "$RES_LOG"

log using "$RES_LOG/iv_audit_detail_v2_`RUN_TAG'.log", text replace

capture ssc install rangestat, replace
capture ssc install ivreg2, replace
capture ssc install ranktest, replace

tempname H
tempfile audit
postfile `H' str10 group str2 iv_set str12 stage str80 varname str120 detail double N miss_rate sd stat1 stat2 stat3 using "`audit'", replace

foreach G in G1_17_19 G2_39_41 {
    di as txt _n "========== IV AUDIT FOR `G' =========="

    use "$DATA_WORK/firststage_`G'.dta", clear

    sort firmid year
    isid firmid year, sort
    xtset firmid year

    capture drop phi_lag klag mlag xlag llag ksqlag lsqlag llagsq klagsq mlagsq xlagsq llagklag llagmlag llagxlag klagmlag klagxlag mlagxlag llag2 llagk mlagl mlagxlagk xlagk mlagk mlagllag llagxlagmlag xlagllag xllagl lages lages2q klages shat_lag kl

    gen double phi_lag = L.phi
    gen double klag   = L.k
    gen double mlag   = L.m
    gen double xlag   = L.x
    gen double llag   = L.l
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

    gen double llag2  = L2.l
    gen double llagk  = llag*k
    gen double mlagl  = mlag*l
    gen double mlagxlagk = mlagxlag*k
    gen double xlagk  = xlag*k
    gen double mlagk  = mlag*k
    gen double mlagllag = mlag*llag
    gen double llagxlagmlag = llagxlag*mlag
    gen double xlagllag = xlag*llag
    gen double xllagl  = xlag*l

    gen double lages   = L.es
    gen double lages2q = L.es2q
    gen double klages  = k*lages
    gen double shat_lag = L.shat
    gen double kl = k*l

    capture confirm variable const
    if _rc gen byte const = 1

    capture drop temp_l temp_k temp_m l_ind_yr k_ind_yr m_ind_yr
    gen temp_l = l
    gen temp_k = k
    gen temp_m = m

    rangestat (mean) temp_l, by(cic2 year) interval(firmid . .) excludeself
    rename temp_l_mean l_ind_yr
    rangestat (mean) temp_k, by(cic2 year) interval(firmid . .) excludeself
    rename temp_k_mean k_ind_yr
    rangestat (mean) temp_m, by(cic2 year) interval(firmid . .) excludeself
    rename temp_m_mean m_ind_yr
    drop temp_*

    merge m:1 firmid year using "$DATA_RAW/firm_year_IVs_Ztariff_ZHHI.dta"
    keep if _merge==3
    drop _merge
    drop if missing(Z_tariff, Z_HHI_post)

    capture drop Dy*
    capture drop dy2000 dy2001 dy2002 dy2003 dy2004 dy2005 dy2006 dy2007
    levelsof year, local(yrs)
    local base : word 1 of `yrs'
    quietly tab year, gen(Dy)
    local j = 1
    foreach y of local yrs {
        if `y' == `base' drop Dy`j'
        else               rename Dy`j' dy`y'
        local ++j
    }

    capture confirm variable lnagelag
    if _rc gen double lnagelag = L.lnage

    foreach yy in 2002 2003 2004 2005 2006 2007 {
        capture confirm variable dy`yy'
        if _rc gen byte dy`yy' = 0
    }

    drop if missing(const, r, l, k, phi, phi_lag, llag, klag, mlag, lsqlag, ksqlag, ///
        lsq, ksq, m, es, es2q, lages, lages2q, shat, shat_lag, lnage, firmcat, lnmana, ///
        lnagelag, firmcat_2, firmcat_3, dy2002, dy2003, dy2004, dy2005, dy2006, dy2007, klages, mlagxlag)

    quietly count
    local Nsample = r(N)
    di as txt "sample after build = `Nsample'"

    local endog4 l k m
    if "`G'" == "G1_17_19" {
        local z_A l llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_post
        local z_B l llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
        local z_C llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
    }
    else {
        local z_A llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_post
        local z_B llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
        local z_C l llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
    }

    foreach S in A B C {
        local z_excl ``z_`S''
        local miss 0

        foreach z of local z_excl {
            capture confirm variable `z'
            if _rc {
                local miss 1
                post `H' ("`G'") ("`S'") ("exist") ("`z'") ("missing variable") (`Nsample') (.) (.) (.) (.) (.)
            }
            else {
                quietly count
                local NN = r(N)
                quietly count if missing(`z')
                local mr = r(N)/`NN'
                quietly summarize `z', meanonly
                local sdz = r(sd)
                post `H' ("`G'") ("`S'") ("varstat") ("`z'") ("ok") (`NN') (`mr') (`sdz') (.) (.) (.)
            }
        }

        if `miss' {
            post `H' ("`G'") ("`S'") ("ivreg2") (".") ("skipped: missing vars") (`Nsample') (.) (.) (.) (.) (.)
            continue
        }

        capture noisily ivreg2 r const dy2002-dy2007 lnage firmcat_2 firmcat_3 ///
            (`endog4' = `z_excl') lsq ksq, nocons robust cluster(firmid) first

        local rc = _rc
        if `rc' {
            post `H' ("`G'") ("`S'") ("ivreg2") (".") ("failed rc=`rc'") (`Nsample') (.) (.) (.) (.) (.)
        }
        else {
            local jp = .
            local jv = .
            local wid = .
            capture scalar __jp = e(jp)
            if !_rc local jp = scalar(__jp)
            capture scalar __j = e(j)
            if !_rc local jv = scalar(__j)
            capture scalar __wid = e(widstat)
            if !_rc local wid = scalar(__wid)
            post `H' ("`G'") ("`S'") ("ivreg2") (".") ("ok") (e(N)) (.) (.) (`jp') (`jv') (`wid')
        }

        foreach y in l k m {
            capture noisily regress `y' `z_excl' const dy2002-dy2007 lnage firmcat_2 firmcat_3 lsq ksq, vce(cluster firmid) nocons
            if _rc {
                post `H' ("`G'") ("`S'") ("firstF") ("`y'") ("reg failed") (`Nsample') (.) (.) (.) (.) (.)
            }
            else {
                capture test `z_excl'
                if _rc {
                    post `H' ("`G'") ("`S'") ("firstF") ("`y'") ("test failed") (`Nsample') (.) (.) (.) (.) (.)
                }
                else {
                    post `H' ("`G'") ("`S'") ("firstF") ("`y'") ("joint excluded IV") (`Nsample') (.) (.) (r(F)) (r(df)) (r(df_r))
                }
            }
        }
    }
}

postclose `H'
use "`audit'", clear
order group iv_set stage varname detail N miss_rate sd stat1 stat2 stat3
sort group iv_set stage varname
save "$RES_DATA/iv_audit_detail.dta", replace
export delimited using "$RES_DATA/iv_audit_detail.csv", replace

di as res "saved: $RES_DATA/iv_audit_detail.dta"
di as res "saved: $RES_DATA/iv_audit_detail.csv"

log close _all
