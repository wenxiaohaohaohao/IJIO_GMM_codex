clear
set more off
local wd = c(pwd)
global ROOT "`wd'/1017/1022_non_hicks"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"
capture noisily do "$ROOT/code/master/run_group_G1.do"
exit _rc, clear
