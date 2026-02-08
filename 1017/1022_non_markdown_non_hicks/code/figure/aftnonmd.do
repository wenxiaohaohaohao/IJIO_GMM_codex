clear all
set more off

capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_markdown_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"
use "$DATA_WORK/firststage-nonhicksnonmd.dta", clear
merge m:1 cic2 using "$RES_DATA/gmm_point_industry.dta"
keep if _merge==3
drop _merge
gen denu=2*b_S2q/b_m
gen aft=denu*S2q+m-x
* --------- DEFINE TWO BIG GROUPS ----------
* Group 1: cic2 in {17,18,19}; Group 2: cic2 in {39,40,41}
gen byte biggrp = .
replace biggrp = 1 if inlist(cic2, 17, 18, 19)
replace biggrp = 2 if inlist(cic2, 39, 40, 41)
* 保留两大组样本
keep if inlist(biggrp, 1, 2)

label define BIGGRP 1 "Group 1: 17/18/19" 2 "Group 2: 39/40/41"
label values biggrp BIGGRP
save "$DATA_WORK/nonmdnon-Hicks.dta", replace

