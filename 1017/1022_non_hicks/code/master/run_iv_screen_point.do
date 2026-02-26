clear all
set more off
capture log close _all

* IV screening: point estimation only, no bootstrap
if ("$ROOT"=="") global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
if ("$CODE"=="") global CODE "$ROOT/code"
if ("$DATA_WORK"=="") global DATA_WORK "$ROOT/data/work"
if ("$RES_DATA"=="") global RES_DATA "$ROOT/results/data"
if ("$RES_LOG"=="") global RES_LOG "$ROOT/results/logs"

capture mkdir "$RES_DATA"
capture mkdir "$RES_LOG"

local today = string(date(c(current_date), "DMY"), "%tdCCYYNNDD")
local now = subinstr(c(current_time), ":", "", .)
local tag = "`today'_`now'"
log using "$RES_LOG/iv_screen_point_`tag'.log", text replace

tempname H
postfile `H' str4 iv_set str10 group int rc double gmm_conv J_opt J_df J_p b_m elas_k_mean elas_l_mean elas_m_mean elas_k_negshare elas_l_negshare elas_m_negshare N using "$RES_DATA/iv_screen_point_`tag'.dta", replace

local ivsets "A B C A1 A2 A3"

foreach s of local ivsets {
    di as txt _n "=============================="
    di as txt "IV screening run: IV_SET=`s'"
    di as txt "=============================="

    * Isolate each IV run in its own output folder to avoid file-lock conflicts
    global DATA_WORK "$ROOT/data/work/ivscreen_`s'"
    global RES_LOG "$ROOT/results/logs/ivscreen_`s'"
    capture mkdir "$DATA_WORK"
    capture mkdir "$RES_LOG"

    global TARGET_GROUP "ALL"
    global RUN_POINT_ONLY 1
    global RUN_BOOT 0
    global RUN_DIAG 0
    global IV_SET "`s'"

    capture noisily do "$CODE/master/run_step1_point_diag.do"
    local rc_run = _rc

    if (`rc_run'==0 & fileexists("$DATA_WORK/nonhicks_points_by_group.dta")) {
        preserve
            use "$DATA_WORK/nonhicks_points_by_group.dta", clear
            quietly count
            if (r(N)==0) {
                post `H' ("`s'") ("EMPTY") (`rc_run') (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.)
            }
            else {
                forvalues i = 1/`=_N' {
                    post `H' ("`s'") (group[`i']) (`rc_run') (gmm_conv[`i']) (J_opt[`i']) (J_df[`i']) (J_p[`i']) (b_m[`i']) (elas_k_mean[`i']) (elas_l_mean[`i']) (elas_m_mean[`i']) (elas_k_negshare[`i']) (elas_l_negshare[`i']) (elas_m_negshare[`i']) (N[`i'])
                }
            }
        restore
    }
    else {
        * run failed: record one line
        post `H' ("`s'") ("ALL_FAIL") (`rc_run') (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.)

        * if partial group outputs exist, capture them as well
        foreach g in G1_17_19 G2_39_41 {
            if (fileexists("$DATA_WORK/gmm_point_group_`g'.dta")) {
                preserve
                    use "$DATA_WORK/gmm_point_group_`g'.dta", clear
                    quietly count
                    if (r(N)>0) {
                        forvalues i = 1/`=_N' {
                            post `H' ("`s'") (group[`i']) (`rc_run') (gmm_conv[`i']) (J_opt[`i']) (J_df[`i']) (J_p[`i']) (b_m[`i']) (elas_k_mean[`i']) (elas_l_mean[`i']) (elas_m_mean[`i']) (elas_k_negshare[`i']) (elas_l_negshare[`i']) (elas_m_negshare[`i']) (N[`i'])
                        }
                    }
                restore
            }
        }
    }
}

postclose `H'

use "$RES_DATA/iv_screen_point_`tag'.dta", clear
order iv_set group rc gmm_conv J_opt J_df J_p b_m elas_k_mean elas_l_mean elas_m_mean elas_k_negshare elas_l_negshare elas_m_negshare N
sort iv_set group

save "$RES_DATA/iv_screen_point_latest.dta", replace

export delimited using "$RES_DATA/iv_screen_point_latest.csv", replace

di as res "Saved: $RES_DATA/iv_screen_point_latest.dta"
di as res "Saved: $RES_DATA/iv_screen_point_latest.csv"

log close

