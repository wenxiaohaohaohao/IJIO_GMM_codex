clear
set more off
capture log close _all
log using "1017/1022_non_hicks/results/logs/tmp_point_G1G2_driver.log", text replace

local wd = c(pwd)
global ROOT "`wd'/1017/1022_non_hicks"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"

di as text "start " c(current_time) " " c(current_date)
di as text "ROOT=$ROOT"

capture noisily do "$ROOT/code/master/run_group_G1.do"
local rc1 = _rc
di as text "rc_g1=" `rc1'

capture noisily do "$ROOT/code/master/run_group_G2.do"
local rc2 = _rc
di as text "rc_g2=" `rc2'

di as text "end " c(current_time) " " c(current_date)
log close _all

file open fh using "1017/1022_non_hicks/results/logs/tmp_point_G1G2_rc.txt", write replace
file write fh "rc_g1=" `rc1' _n
file write fh "rc_g2=" `rc2' _n
file close fh

exit 0, clear
