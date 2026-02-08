* Main Stata analysis entry point
local dofile = c(current_do)
local do_dir : dirname "`dofile'"

do "`do_dir'\00_setup.do"

* TODO: replace with your data and analysis
* use "$RAW_DATA\mydata.dta", clear
* gen ln_y = ln(y)
* save "$PROC_DATA\mydata_processed.dta", replace

* Optional exports
* do "`do_dir'\90_export.do"
