clear
set more off
global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work/debug_iv_override"
global RES_DATA "$ROOT/results/data"
global RES_LOG "$ROOT/results/logs/debug_iv_override"
global TARGET_GROUP "G1_17_19"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 0
global ROBUST_INIT 0
global IV_SET "C"
global IV_Z_G1 "const llag mlag lages lages2q l_ind_yr m_ind_yr k_ind_yr Z_tariff Z_HHI_post"
global IV_Z_G2 ""
capture mkdir "$DATA_WORK"
capture mkdir "$RES_LOG"
do "$ROOT/code/master/Master_Non_hicks.do"
