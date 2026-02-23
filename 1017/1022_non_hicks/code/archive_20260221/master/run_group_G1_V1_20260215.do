* run_group_G1.do
clear all
set more off
global GROUP_NAME G1_17_19
capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


cd "$ROOT"
do "$CODE/estimate/bootstrap1229_group.do" 

