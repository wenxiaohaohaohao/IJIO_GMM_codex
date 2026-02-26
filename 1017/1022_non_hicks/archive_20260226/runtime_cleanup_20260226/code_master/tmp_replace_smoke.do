clear all
set more off
log using "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/logs/tmp_replace_smoke.log", text replace
clear
set obs 1
gen x=1
save "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/data/work/tmp_replace_smoke.dta", replace
replace x=2
save "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/data/work/tmp_replace_smoke.dta", replace
di "REPLACE_SMOKE_OK"
log close
exit
