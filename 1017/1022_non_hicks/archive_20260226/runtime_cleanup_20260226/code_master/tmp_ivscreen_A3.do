clear all
set more off
global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
global CODE "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/code"
global DATA_RAW "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/data/raw"
global DATA_WORK "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/data/work/ivscreen_A3"
global RES_DATA "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/data"
global RES_LOG "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/logs/ivscreen_A3"
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 0
global IV_SET "A3"
do "$ROOT/code/master/run_step1_point_diag.do"
