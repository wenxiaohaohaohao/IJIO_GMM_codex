*******************************************************
* Counterfactual cost-share plots + decomposition table
* Three curves coincide at base year (2000 or sector first year)
* Update: Constant-Technology also fixes mdcd3 at base year (b0)
*******************************************************
clear all
set more off

* --------- FILE PATHS ----------
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"
local d1 "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks\firststage-nonhicks.dta"
local d2 "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks\gmm_point_industry.dta"

* --------- LOAD base ----------
use "`d1'", clear
merge m:1 cic2 using "`d2'"
keep if _merge==3
drop _merge

* --------- FILTERS ----------
drop if es==.
drop if es2q==.

* --------- CORE VARIABLES ----------
gen markdowncd1      = 1 - (1/b_m)*es                          // a
gen mdcd2            = domesticint/importint
gen mdcd3            = (1/b_m)*es                               // b
gen markdownnonHicks = markdowncd1*mdcd2/mdcd3                  // t  (technology term)

ssc install winsor2, replace
local v markdownnonHicks

winsor2 `v', trim cuts(2 98) by(cic2 year)
summ `v', detail

drop markdownnonHicks
rename markdownnonHicks_tr markdownnonHicks


* Optional: AFT construction if needed later
gen denominator = -2*b_m*b_essq
gen numerator   = b_es*b_es
gen denu        = numerator/denominator
gen aft         = denu*es + m - x

save "mdnon-Hicks.dta", replace


* (Optional firm-level actual; not used after fix)
capture drop counterfactualshare
gen counterfactualshare = markdowncd1/(markdowncd1 + mdcd3*markdownnonHicks)

* ===============================================================
*      AGGREGATION + CONSISTENT "ACTUAL" + COUNTERFACTUALS
* ===============================================================
preserve
    * Revenue-weighted sector-year means (one row per cic2-year)
    collapse (mean) markdowncd1 markdownnonHicks mdcd3 [aw=R], by(cic2 year)
    rename markdowncd1       w_markdowncd1        // a
    rename markdownnonHicks  w_markdownnonHicks   // t
    rename mdcd3             w_mdcd3              // b

    * Consistent ACTUAL from aggregated components (ratio form)
    gen cshare_actual = w_markdowncd1 / ( w_markdowncd1 + w_mdcd3*w_markdownnonHicks )
    label var cshare_actual "Actual"

    * Base year: prefer 2000; if missing, use sector's first year
    local baseY 2000
    bys cic2: egen firstyear = min(year)
    gen baseflag = (year==`baseY')
    bys cic2: egen has2000 = max(baseflag)
    bys cic2: gen base_year = `baseY' if has2000==1
    bys cic2: replace base_year = firstyear if missing(base_year)

    * Anchor values at base year (sector-specific): a0, b0, t0
    foreach v in w_markdownnonHicks w_markdowncd1 w_mdcd3 {
        gen __tmp_`v'_base = `v' if year==base_year
        bys cic2: egen `v'_base = total(__tmp_`v'_base)
        drop __tmp_`v'_base
    }

    * -----------------------------------------------------------
    * Counterfactual lines for plotting
    *   - Constant Technology: hold t=t0 AND b=b0, only a varies
    *   - Constant Markdown:   hold a=a0 AND b=b0, only t varies
    * -----------------------------------------------------------
    gen cshare_constTech = w_markdowncd1 / ( w_markdowncd1 + w_mdcd3_base*w_markdownnonHicks_base )
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

    * =============================================================== *
    *   DECOMPOSITION TABLE — PATH (constant lines) + SHAPLEY         *
    *   Convention: Constant-Technology fixes (b0,t0)                  *
    *               Constant-Markdown fixes (a0,b0)                    *
    * =============================================================== *
    tempfile agg_long
    save `agg_long', replace

    keep cic2 year base_year w_markdowncd1 w_mdcd3 w_markdownnonHicks cshare_actual

    * End year = 2007 if available; else sector's last observed year
    bys cic2: egen has2007 = max(year==2007)
    bys cic2: egen lastyr  = max(year)
    bys cic2: gen end_year = 2007 if has2007==1
    bys cic2: replace end_year = lastyr if missing(end_year)

    * Flags for base & end rows
    gen is_base = (year==base_year)
    gen is_end  = (year==end_year)

    * Extract base values (a0,b0,t0,S0)
    gen a0_tmp = w_markdowncd1       if is_base
    gen b0_tmp = w_mdcd3             if is_base
    gen t0_tmp = w_markdownnonHicks  if is_base
    gen S0_tmp = cshare_actual       if is_base
    bys cic2: egen a0 = max(a0_tmp)
    bys cic2: egen b0 = max(b0_tmp)
    bys cic2: egen t0 = max(t0_tmp)
    bys cic2: egen S0 = max(S0_tmp)

    * Extract end values (a1,b1,t1,S1)
    gen a1_tmp = w_markdowncd1       if is_end
    gen b1_tmp = w_mdcd3             if is_end
    gen t1_tmp = w_markdownnonHicks  if is_end
    gen S1_tmp = cshare_actual       if is_end
    bys cic2: egen a1 = max(a1_tmp)
    bys cic2: egen b1 = max(b1_tmp)
    bys cic2: egen t1 = max(t1_tmp)
    bys cic2: egen S1 = max(S1_tmp)

    * One row per sector for decomposition
    collapse (max) base_year end_year a0 b0 t0 a1 b1 t1 S0 S1, by(cic2)
    gen dS = S1 - S0

    * -----------------------------------------------------------
    * Counterfactual levels aligned with plotting conventions
    *   - S_M1T0: markdown moves to a1, technology fixed at (b0,t0)
    *   - S_M0T1: technology moves to t1, markdown fixed at (a0,b0)
    * -----------------------------------------------------------
    gen S_M1T0 = a1/(a1 + b0*t0) if a1>0 & b0>0 & t0>0
    gen S_M0T1 = a0/(a0 + b0*t1) if a0>0 & b0>0 & t1>0

    * -------- PATH (matches constant lines) --------
    gen md_path     = S_M1T0 - S0
    gen tech_path   = S_M0T1 - S0
    gen inter_path  = dS - md_path - tech_path

    gen pct_md_path     = 100*md_path/dS       if dS!=0
    gen pct_tech_path   = 100*tech_path/dS     if dS!=0
    gen pct_interaction = 100*inter_path/dS    if dS!=0

    * -------- SHAPLEY (additive; same S_M1T0, S_M0T1) --------
    gen C_MD   = 0.5*((S_M1T0 - S0) + (S1 - S_M0T1))
    gen C_Tech = 0.5*((S_M0T1 - S0) + (S1 - S_M1T0))
    gen pct_MD_shapley   = 100*C_MD/dS     if dS!=0
    gen pct_Tech_shapley = 100*C_Tech/dS   if dS!=0

    * Sector names
    capture decode cic2, gen(sector_name)
    if _rc {
        label values cic2 cic2lbl
        decode cic2, gen(sector_name)
    }

    * -------- Nicely formatted table in Stata only --------
    order cic2 sector_name base_year end_year ///
          S0 S1 dS ///
          md_path tech_path inter_path pct_md_path pct_tech_path pct_interaction ///
          C_MD C_Tech pct_MD_shapley pct_Tech_shapley

    label var S0               "Actual (base)"
    label var S1               "Actual (end)"
    label var dS               "Δ Actual"
    label var md_path          "Δ via Const-MD path (a→a1; b0,t0)"
    label var tech_path        "Δ via Const-Tech path (t→t1; a0,b0)"
    label var inter_path       "Δ interaction (residual)"
    label var pct_md_path      "% via Const-MD"
    label var pct_tech_path    "% via Const-Tech"
    label var pct_interaction  "% interaction"
    label var C_MD             "Shapley MD"
    label var C_Tech           "Shapley Tech"
    label var pct_MD_shapley   "% Shapley MD"
    label var pct_Tech_shapley "% Shapley Tech"

    format S0 S1 dS md_path tech_path inter_path C_MD C_Tech %9.4f
    format pct_* %9.2f
    sort cic2

    di as txt "{hline 120}"
    di as txt "Foreign-input cost share decline — PATH (constant lines with b0,t0 for Const-Tech) vs SHAPLEY"
    di as txt "PATH: %Const-MD + %Const-Tech + %Interaction = 100"
    di as txt "SHAPLEY: %Shapley MD + %Shapley Tech = 100"
    di as txt "{hline 120}"
    list cic2 sector_name base_year end_year ///
         S0 S1 dS ///
         md_path tech_path inter_path pct_md_path pct_tech_path pct_interaction ///
         C_MD C_Tech pct_MD_shapley pct_Tech_shapley, noobs abbreviate(24)

    * -------- Back to long form for plotting --------
    use `agg_long', clear

    * ---- Plot per sector (solid lines; one-line small legend)
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
