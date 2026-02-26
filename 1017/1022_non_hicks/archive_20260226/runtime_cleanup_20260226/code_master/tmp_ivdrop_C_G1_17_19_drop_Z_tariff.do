clear
set more off
global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
global CODE "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/code"
global DATA_RAW "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/data/raw"
global DATA_WORK "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/data/work/ivdrop_C_G1_17_19_drop_Z_tariff_20260226_100421791"
global RES_DATA "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/data"
global RES_LOG "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/logs/ivdrop_C_G1_17_19_drop_Z_tariff_20260226_100421791"
global TARGET_GROUP "G1_17_19"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 0
global ROBUST_INIT 0
global IV_SET "C"
global IV_Z_G1 "const llag klag mlag lages lages2q l_ind_yr m_ind_yr k_ind_yr Z_HHI_post"
global IV_Z_G2 ""
do "$ROOT/code/master/Master_Non_hicks.do"
