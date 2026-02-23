clear all
set more off

* Step 1 baseline: point estimation + diagnostics only
global ROOT "."
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "A"

do "$ROOT/code/master/Master_Non_hicks.do"
