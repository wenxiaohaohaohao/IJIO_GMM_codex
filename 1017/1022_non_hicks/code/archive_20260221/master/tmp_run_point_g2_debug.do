clear
set more off
capture log close _all
log using "1017/1022_non_hicks/results/logs/tmp_run_g2_point.log", text replace
local wd = c(pwd)
global ROOT "`wd'/1017/1022_non_hicks"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"
di as text "start g2 " c(current_time) " " c(current_date)
do "$ROOT/code/master/run_group_G2.do"
di as text "end g2 " c(current_time) " " c(current_date)
log close _all
exit 0, clear
