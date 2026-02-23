clear all
set more off

global ROOT "."
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"

capture noisily do "1017/1022_non_hicks/code/master/Master_Non_hicks.do"
local rc = _rc
di as text "=== MASTER RC = `rc' ==="
exit `rc'
