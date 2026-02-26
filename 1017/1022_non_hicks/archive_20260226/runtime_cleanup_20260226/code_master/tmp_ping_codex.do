clear all
set more off
capture log close _all
log using "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/logs/tmp_ping_codex.log", text replace
di "PING_CODEX_OK"
log close
exit
