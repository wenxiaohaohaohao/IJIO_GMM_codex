version 18.0
clear all
set more off

* Resolve project root from this do-file location.
local dofile = c(current_do)
local do_dir : dirname "`dofile'"
global PROJECT_ROOT "`do_dir'\..\.."

* Core paths
global RAW_DATA "$PROJECT_ROOT\data\raw"
global PROC_DATA "$PROJECT_ROOT\data\processed"
global OUT_TABLES "$PROJECT_ROOT\output\tables"
global OUT_FIGS "$PROJECT_ROOT\output\figures"

* Ensure folders exist
cap mkdir "$PROJECT_ROOT\data"
cap mkdir "$RAW_DATA"
cap mkdir "$PROC_DATA"
cap mkdir "$PROJECT_ROOT\output"
cap mkdir "$OUT_TABLES"
cap mkdir "$OUT_FIGS"
