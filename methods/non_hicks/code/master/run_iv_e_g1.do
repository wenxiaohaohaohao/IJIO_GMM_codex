clear all
set more off

capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_hicks"
if ("$CODE"=="") global CODE "$ROOT/code"
if ("$DATA_RAW"=="") global DATA_RAW "$ROOT/data/raw"
if ("$DATA_WORK"=="") global DATA_WORK "$ROOT/data/work"
if ("$RES_DATA"=="") global RES_DATA "$ROOT/results/data"
if ("$RES_FIG"=="") global RES_FIG "$ROOT/results/figures"
if ("$RES_LOG"=="") global RES_LOG "$ROOT/results/logs"

global TARGET_GROUP "G1_17_19"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "E"

cd "$ROOT"
do "$CODE/master/Master_Non_hicks.do"
