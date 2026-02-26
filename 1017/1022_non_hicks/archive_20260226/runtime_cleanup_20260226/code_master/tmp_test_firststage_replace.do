clear all
set more off
log using "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/logs/tmp_test_firststage_replace.log", text replace
use "D:/paper/IJIO_GMM_codex_en/firststage.dta", clear
save "D:/paper/IJIO_GMM_codex_en/firststage.dta", replace
di "FIRSTSTAGE_REPLACE_OK"
log close
exit
