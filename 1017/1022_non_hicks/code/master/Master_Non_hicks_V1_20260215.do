/* main_twogroups.do
   Outputs:
     - nonhicks_points_by_group.dta  (points + bootstrap SEs + J + N)
     - nonhicks_ses_by_group.dta     (SEs only, convenience)
*/

* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* STEP 0: SETUP LOGGING (CRITICAL FOR DEBUGGING)
* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
clear all
set more off
* Get current date for log filename
capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"

* Run controls (can be preset before calling this master)
if ("$TARGET_GROUP"=="") global TARGET_GROUP "ALL"     // ALL | G1_17_19 | G2_39_41
if ("$RUN_POINT_ONLY"=="") global RUN_POINT_ONLY 0     // 1 => skip bootstrap in estimate do-file
if ("$RUN_BOOT"=="") global RUN_BOOT 1                 // kept for compatibility; overridden by RUN_POINT_ONLY
if ("$RUN_DIAG"=="") global RUN_DIAG 0


local today = string(date(c(current_date), "DMY"), "%tdCCYYNNDD")
capture log close _all  // Close any existing logs to prevent conflicts

* Create log directory
global LOG_DIR "$RES_LOG"
capture mkdir "$LOG_DIR"
if (_rc != 0 & _rc != 602) {
    di as error "WARNING: mkdir failed, r(`_rc')"
    global LOG_DIR "."
}

* 确保有 ivreg2 和 ranktest
capture which ivreg2
if _rc ssc install ivreg2, replace

capture which ranktest
if _rc ssc install ranktest, replace
* Start comprehensive logging - APPEND mode to preserve previous runs
local log_file "$LOG_DIR/main_twogroups_full_log_`today'.log"
log using "`log_file'", text replace  // REPLACE to avoid appending to old logs

* Add header to log with execution details
di _n(2) "{hline 80}"
di as text "EXECUTION LOG STARTED: $S_TIME $S_DATE"
di as text "LOG FILE: `log_file'"
di as text "STATA VERSION: `c(stata_version)'"
di as text "USER: `c(username)'"
di as text "MACHINE: `c(hostname)'"
di as text "WORKING DIRECTORY: `c(pwd)'"
di "{hline 80}" _n

* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* STEP 1: RUN GMM FOR BOTH GROUPS (WITH ERROR CAPTURE)
* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
cd "$ROOT"

local run_g1 = inlist("$TARGET_GROUP","ALL","G1_17_19")
local run_g2 = inlist("$TARGET_GROUP","ALL","G2_39_41")

if (!`run_g1' & !`run_g2') {
    di as error "Invalid TARGET_GROUP=[$TARGET_GROUP]. Must be ALL, G1_17_19, or G2_39_41."
    exit 198
}

di as text "RUN MODE: TARGET_GROUP=$TARGET_GROUP, RUN_POINT_ONLY=$RUN_POINT_ONLY, RUN_BOOT=$RUN_BOOT"

if `run_g1' {
    capture noisily do "$CODE/master/run_group_G1.do"
    if _rc != 0 {
        local rc = _rc
        di as error _n(2) "!!! FATAL ERROR IN GROUP 1 EXECUTION !!!"
        di as error "Return code: `rc'"
        di as error "Stage   : run_group_G1.do"
        exit `rc'
    }
    else {
        di as result _n(2) ">>> GROUP 1 EXECUTION SUCCESSFUL <<<"
    }
}

if `run_g2' {
    capture noisily do "$CODE/master/run_group_G2.do"
    if _rc != 0 {
        local rc = _rc
        di as error _n(2) "!!! FATAL ERROR IN GROUP 2 EXECUTION !!!"
        di as error "Return code: `rc'"
        di as error "Stage   : run_group_G2.do"
        exit `rc'
    }
    else {
        di as result _n(2) ">>> GROUP 2 EXECUTION SUCCESSFUL <<<"
    }
}

* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* STEP 2: COMBINE RESULTS (WITH DATA VALIDATION)
* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
if `run_g1' {
    confirm file "$DATA_WORK/gmm_point_group_G1_17_19.dta"
    if _rc != 0 {
        di as error "CRITICAL: Missing required file $DATA_WORK/gmm_point_group_G1_17_19.dta"
        exit 601
    }
}
if `run_g2' {
    confirm file "$DATA_WORK/gmm_point_group_G2_39_41.dta"
    if _rc != 0 {
        di as error "CRITICAL: Missing required file $DATA_WORK/gmm_point_group_G2_39_41.dta"
        exit 601
    }
}

if `run_g1' {
    use "$DATA_WORK/gmm_point_group_G1_17_19.dta", clear
    if `run_g2' append using "$DATA_WORK/gmm_point_group_G2_39_41.dta"
}
else {
    use "$DATA_WORK/gmm_point_group_G2_39_41.dta", clear
}

* Data validation checks
di _n(2) ">>> DATA VALIDATION AFTER APPEND <<<"
di "Total observations: " _N
tab group
sum J_unit J_opt, detail

* Critical check for high J-statistics
if r(max) > 50 {
    di as error _n(2) "!!! WARNING: HIGH J-STATISTICS DETECTED !!!"
    di as error "Max J_unit = `=r(max)' - Indicates potential model misspecification"
    di as error "Please check instrument validity and model specification"
}

order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq ///
      b_m se_m b_es se_es b_essq se_essq b_lnage b_firmcat_2 b_firmcat_3 J_unit J_opt J_df J_p N
compress
save "$RES_DATA/nonhicks_points_by_group.dta", replace

* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* STEP 3: CREATE SE-ONLY TABLE
* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
preserve
    keep group se_const se_l se_k se_lsq se_ksq se_m se_es se_essq
    compress
    save "$RES_DATA/nonhicks_ses_by_group.dta", replace
    di as text _n "Saved SE-only table: nonhicks_ses_by_group.dta"
restore

* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* STEP 4: CREATE INDUSTRY-LEVEL MAPPING
* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
clear
if `run_g1' {
    use "$DATA_WORK/gmm_point_group_G1_17_19.dta", clear
    if `run_g2' append using "$DATA_WORK/gmm_point_group_G2_39_41.dta"
}
else {
    use "$DATA_WORK/gmm_point_group_G2_39_41.dta", clear
}

rename group group_pool
gen str10 group = cond(group_pool=="G1_17_19","GI_17_19","GI_39_41")

* Create industry mapping table
preserve
clear
input str10 group_pool byte cic2
"G1_17_19" 17
"G1_17_19" 18
"G1_17_19" 19
"G2_39_41" 39
"G2_39_41" 40
"G2_39_41" 41
end
tempfile map
save "`map'", replace
restore

merge 1:m group_pool using "`map'", keep(match) nogen
drop group_pool J_unit J_opt J_df J_p N
order cic2 group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq ///
      b_m se_m b_es se_es b_essq se_essq b_lnage b_firmcat_2 b_firmcat_3 
	  
label var group "GI group label (mapped by cic2)"
compress
save "$RES_DATA/gmm_point_industry.dta", replace

* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* STEP 5: FINAL SUMMARY & LOG CLOSURE
* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
di _n(2) "{hline 80}"
di as text "EXECUTION SUMMARY:"
di as result "  - Successfully combined results for target group setting: $TARGET_GROUP"
di as result "  - Created nonhicks_points_by_group.dta"
di as result "  - Created nonhicks_ses_by_group.dta"
di as result "  - Created gmm_point_industry.dta (industry-level mapping)"
di as text "OUTPUT FILES:"
di as text "  `c(pwd)'/nonhicks_points_by_group.dta"
di as text "  `c(pwd)'/nonhicks_ses_by_group.dta"
di as text "  `c(pwd)'/gmm_point_industry.dta"
di as text "LOG FILE:"
di as text "  `log_file'"
di "{hline 80}" _n

* Save copy of log with timestamped name in main directory
capture copy "`log_file'" "$RES_LOG/main_twogroups_final_log_`today'.log"
if _rc == 0 {
    di as text "Copied log to: main_twogroups_final_log_`today'.log"
}
else {
    di as error "Failed to copy log file"
}

* Properly close logging
log close

* Final confirmation
di as result _n(2) ">>> ALL OPERATIONS COMPLETED SUCCESSFULLY <<<"
di as text "Log file saved to: `log_file'"
exit
