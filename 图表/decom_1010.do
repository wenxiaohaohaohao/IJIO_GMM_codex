*******************************************************
* Counterfactual cost-share plots by sector (solid lines)
* Three curves coincide at base year (2000 or sector first year)
*******************************************************
clear all
set more off

* --------- FILE PATHS ----------
cd "C:\Users\xwang4\Downloads\0903_updated_wenxiao\0903_updated_wenxiao\Non_hicks"
local d1 "C:\Users\xwang4\Downloads\0903_updated_wenxiao\0903_updated_wenxiao\Non_hicks\firststage-nonhicks.dta"
local d2 "C:\Users\xwang4\Downloads\0903_updated_wenxiao\0903_updated_wenxiao\Non_hicks\nonhicks_gmm_by_cic2_withSE.dta"

* --------- LOAD + MERGE ----------
use "`d1'", clear
merge m:1 cic2 using "`d2'"
keep if _merge==3
drop _merge

* --------- FILTERS ----------
drop if es==.
drop if es2q==.

* --------- CORE VARIABLES ----------
gen markdowncd1 = 1 - (1/b_m)*es
gen mdcd2       = domesticint/importint
gen mdcd3       = (1/b_m)*es
gen markdownnonHicks = markdowncd1*mdcd2/mdcd3

gen denominator = -2*b_m*b_essq
gen numerator   = b_es*b_es
gen denu        = numerator/denominator
gen aft         = denu*es + m - x

save "mdnon-Hicks.dta", replace

bys cic2 year: egen totalR = total(R)
gen  weight = R/totalR
bys cic2 year: egen sectoraft = total(aft*weight)
summarize sectoraft, detail

* (Optional firm-level actual; not used in plotting after fix)
capture drop counterfactualshare
gen counterfactualshare = markdowncd1/(markdowncd1 + mdcd3*markdownnonHicks)

* ===============================================================
*      AGGREGATION + CONSISTENT "ACTUAL" + COUNTERFACTUALS
* ===============================================================
preserve
    * Revenue-weighted sector-year means (one row per cic2-year)
    collapse (mean) markdowncd1 markdownnonHicks mdcd3 [aw=R], by(cic2 year)
    rename markdowncd1       w_markdowncd1
    rename markdownnonHicks  w_markdownnonHicks
    rename mdcd3             w_mdcd3

    * Consistent ACTUAL from aggregated components (ratio of weighted means)
    gen cshare_actual = w_markdowncd1 / ( w_markdowncd1 + w_mdcd3*w_markdownnonHicks)
    label var cshare_actual "Actual"

    * Base year: prefer 2000; if missing, use sector's first year
    local baseY 2000
    bys cic2: egen firstyear = min(year)
    gen baseflag = (year==`baseY')
    bys cic2: egen has2000 = max(baseflag)
    bys cic2: gen base_year = `baseY' if has2000==1
    bys cic2: replace base_year = firstyear if missing(base_year)

    * Anchor values at base year (sector-specific)
    foreach v in w_markdownnonHicks w_markdowncd1 w_mdcd3 {
        gen __tmp_`v'_base = `v' if year==base_year
        bys cic2: egen `v'_base = total(__tmp_`v'_base)
        drop __tmp_`v'_base
    }

    * Counterfactuals (same functional form, different components fixed)
    gen cshare_constTech = w_markdowncd1 / ( w_markdowncd1 + w_mdcd3*w_markdownnonHicks_base )
    label var cshare_constTech "Constant Technology"

    gen cshare_constMD   = w_markdowncd1_base / ( w_markdowncd1_base + w_mdcd3_base*w_markdownnonHicks )
    label var cshare_constMD "Constant Markdown"

    * ---- Styling locals ----
    local xmin 2000
    local xmax 2007
    local L1 "Actual"
    local L2 "Constant Markdown"
    local L3 "Constant Technology"

    * ---- Sector names (value labels). Extend as needed.
    capture label drop cic2lbl
    label define cic2lbl ///
        17 "Textile" ///
        18 "Textile and Products" ///
        19 "Leather and Products" ///
        39 "Electrical Machinery" ///
        40 "Communication and Computer" ///
        41 "Measuring Instruments", modify
    label values cic2 cic2lbl

    * ---- Plot per sector (solid lines; one-line small legend; titles "Sector #: Name")
    levelsof cic2, local(sectors)
    foreach s of local sectors {

        * Sector display name from value label; fallback to code
        local lblname : value label cic2
        if "`lblname'"=="" local sectorname "CIC2 `s'"
        else {
            local sectorname : label `lblname' `s'
            if `"`sectorname'"'=="" local sectorname "CIC2 `s'"
        }
        * Safe filename token
        local sectorfn : display strtoname("`sectorname'")

        twoway ///
          (connected cshare_actual    year if cic2==`s', ///
              lcolor(blue)  lpattern(solid) lwidth(medium) ///
              msymbol(O) mcolor(blue)  mfcolor(none) msize(medlarge) sort) ///
          (connected cshare_constTech year if cic2==`s', ///
              lcolor(red)   lpattern(solid) lwidth(medium) ///
              msymbol(O) mcolor(red)   mfcolor(none) msize(medlarge) sort) ///
          (connected cshare_constMD   year if cic2==`s', ///
              lcolor(green) lpattern(solid) lwidth(medium) ///
              msymbol(O) mcolor(green) mfcolor(none) msize(medlarge) sort), ///
          legend( order(1 2 3) ///
                  label(1 "`L1'") ///
                  label(2 "`L2'") ///
                  label(3 "`L3'") ///
                  position(6) ring(1) rows(1) cols(3) size(small) ///
                  region(lstyle(none)) ) ///
          ytitle("Foreign input cost share") ///
          xtitle("Year") ///
          title("Sector `s': `sectorname'") ///
          xlabel(`xmin'(1)`xmax', grid) ///
          xscale(range(`xmin' `xmax')) ///
          ylabel(, grid) ///
          graphregion(color(white) lstyle(solid) lcolor(black)) ///
          plotregion(fcolor(white) lstyle(solid) lcolor(black))

        graph export "counterfactualshare_`sectorfn'.png", replace width(1200)
    }
restore
