clear all
set more off

* Step 1 baseline: point estimation + diagnostics only
global ROOT "."
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"

* Isolate Step 1 outputs to avoid replace-collision on existing files
local run_date = string(date(c(current_date), "DMY"), "%tdCCYYNNDD")
local run_time = subinstr(c(current_time), ":", "", .)
global RUN_TAG "`run_date'_`run_time'"
global DATA_WORK "$ROOT/data/work/run_$RUN_TAG"
global RES_DATA "$ROOT/results/data/run_$RUN_TAG"
global RES_LOG "$ROOT/results/logs/run_$RUN_TAG"

capture mkdir "$ROOT/data/work"
capture mkdir "$ROOT/results"
capture mkdir "$ROOT/results/data"
capture mkdir "$ROOT/results/logs"
capture mkdir "$DATA_WORK"
capture mkdir "$RES_DATA"
capture mkdir "$RES_LOG"

di as txt "STEP1 RUN_TAG = $RUN_TAG"
di as txt "STEP1 DATA_WORK = $DATA_WORK"
di as txt "STEP1 RES_DATA  = $RES_DATA"
di as txt "STEP1 RES_LOG   = $RES_LOG"

do "$ROOT/code/master/Master_Non_hicks.do"
