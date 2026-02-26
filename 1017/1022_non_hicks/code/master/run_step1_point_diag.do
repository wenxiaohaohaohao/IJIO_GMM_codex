* Step 1 baseline: point estimation + diagnostics only
* Setup: Use standard output directories (no timestamped subdirectories)
clear all
set more off

if ("$ROOT"=="") global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
if ("$CODE"=="") global CODE "$ROOT/code"
if ("$DATA_RAW"=="") global DATA_RAW "$ROOT/data/raw"
if ("$DATA_WORK"=="") global DATA_WORK "$ROOT/data/work"
if ("$RES_DATA"=="") global RES_DATA "$ROOT/results/data"
if ("$RES_FIG"=="") global RES_FIG "$ROOT/results/figures"
if ("$RES_LOG"=="") global RES_LOG "$ROOT/results/logs"

* Run controls (can be preset before calling this script)
if ("$TARGET_GROUP"=="") global TARGET_GROUP "ALL"
if ("$RUN_POINT_ONLY"=="") global RUN_POINT_ONLY 1
if ("$RUN_BOOT"=="") global RUN_BOOT 0
if ("$RUN_DIAG"=="") global RUN_DIAG 1
if ("$IV_SET"=="") global IV_SET "A"

* Create standard output directories
capture mkdir "$DATA_WORK"
capture mkdir "$RES_DATA"
capture mkdir "$RES_FIG"
capture mkdir "$RES_LOG"

* Force runner log into results/logs to avoid root-level stray logs
capture log close _all
log using "$RES_LOG/run_step1_point_diag.log", text replace

di as txt "STEP1 Configuration:"
di as txt "  ROOT      = $ROOT"
di as txt "  DATA_WORK = $DATA_WORK"
di as txt "  RES_DATA  = $RES_DATA"
di as txt "  RES_LOG   = $RES_LOG"

do "$ROOT/code/master/Master_Non_hicks.do"
log close
