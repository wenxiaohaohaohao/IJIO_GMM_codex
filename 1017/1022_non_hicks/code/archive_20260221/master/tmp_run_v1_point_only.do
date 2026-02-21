clear
set more off
local wd = c(pwd)
global ROOT "`wd'/1017/1022_non_hicks"
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"

capture noisily do "$ROOT/code/master/Master_Non_hicks.do"
local rc = _rc

file open fh using "1017/1022_non_hicks/results/logs/tmp_driver_rc.txt", write replace
file write fh "rc=" `rc' _n
file write fh "time=" c(current_time) " date=" c(current_date) _n
file close fh

exit `rc', clear
