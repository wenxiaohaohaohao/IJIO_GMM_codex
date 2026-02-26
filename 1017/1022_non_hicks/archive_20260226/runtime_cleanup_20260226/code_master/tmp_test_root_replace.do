clear all
set more off
log using "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/logs/tmp_test_root_replace.log", text replace
clear
set obs 1
gen x=1
save "D:/paper/IJIO_GMM_codex_en/tmp_root_replace_probe.dta", replace
replace x=2
save "D:/paper/IJIO_GMM_codex_en/tmp_root_replace_probe.dta", replace
di "ROOT_REPLACE_OK"
log close
exit
