****************************************************
* Descriptive statistics (JIE-style) for six industries
* Outputs (默认只导出"水平"表；log 表可在附录开关打开)：
*   - Table1_desc.tex                (overall sample, levels)
*   - Table2_byOwnership.tex         (SOE vs Private vs Foreign, levels)
* [可选附录]
*   - App_TableA1_desc_logs.tex      (overall sample, logs)
*   - App_TableA2_byOwnership_logs.tex (by ownership, logs)
****************************************************

clear all
set more off

*==========================
* 0) User switches
*==========================
* 是否额外导出"log 变量"的附录表（0=否，1=是）
local MAKE_APPENDIX_LOGS 0

*==========================
* 1) Load & keep six CIC2
*==========================
use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\Non_hicks\firststage.dta", clear
keep if inlist(cic2,17,18,19,39,40,41)

*==========================
* 2) Variable labels (English)
*==========================
capture label var K          "Capital stock (K)"
capture label var L          "Employment (L)"
capture label var MI         "Intermediate inputs (M, domestic)"
capture label var importint  "Imported inputs (X)"
capture label var R          "Revenue (current prices)"
capture label var Q          "Real output (Q)"
capture label var WL         "Wage bill"
capture label var Mana       "Management fees"
capture label var age        "Firm age (years)"
capture label var firmtype   "Ownership (registry type)"
capture label var cic2       "Industry (2-digit CIC)"
capture label var city       "City"

*==========================
* 3) Ownership trichotomy: own3 = {1 SOE, 2 Private, 3 Foreign}
*    优先用 regist；若没有则回退 firmtype（中文标签）
*==========================
capture drop own3
gen own3 = .

capture confirm variable regist
if !_rc {
    * >>> 根据你的编码规则细化，以下仅示例 <<<
    replace own3 = 1 if inlist(regist,110,141,143,151)                        // State-owned
    replace own3 = 2 if inlist(regist,150,159,160,170,171,172,173,174)         // Private
    replace own3 = 3 if inrange(regist,200,340)                                // Foreign-invested incl. HMT
}
else {
    capture confirm variable firmtype
    if !_rc {
        decode firmtype, gen(_firmtype_txt)
        replace own3 = 1 if regexm(_firmtype_txt, "国有|国有独资|集体")
        replace own3 = 2 if regexm(_firmtype_txt, "私营|民营|股份|有限责任")
        replace own3 = 3 if regexm(_firmtype_txt, "外商|外资|合资|合作|港澳台")
        drop _firmtype_txt
    }
}

label define own3 1 "State-owned" 2 "Private" 3 "Foreign-invested"
label values own3 own3

*==========================
* 4) Construct levels & logs / derived vars
*==========================
* Wage per worker (level) + its log
capture drop wagepc lnk lnl lnm lnx lnr lnq lnwl lnage lnmana
gen double wagepc = WL/L if WL>0 & L>0
label var wagepc "Wage per worker"

gen lnk    = ln(K)           if K>0
gen lnl    = ln(L)           if L>0
gen lnm    = ln(MI)          if MI>0
gen lnx    = ln(importint)   if importint>0
gen lnr    = ln(R)           if R>0
gen lnq    = ln(Q)           if Q>0
gen lnwl   = ln(wagepc)      if wagepc>0



label var lnk    "log Capital (K)"
label var lnl    "log Employment (L)"
label var lnm    "log Domestic inputs (M)"
label var lnx    "log Imported inputs (X)"
label var lnr    "log Revenue"
label var lnq    "log Real output"
label var lnwl   "log Wage per worker"
label var lnage  "log Firm age"
label var lnmana "log Management fees"

* 变量清单（水平与 log 分开，正文只用水平）
local VARS_LVL  K L MI importint R Q WL wagepc age Mana
local VARS_LOG  lnk lnl lnm lnx lnr lnq lnwl lnage lnmana

*==========================
* 5) Install estout if needed
*==========================
cap which estpost
if _rc ssc install estout, replace

*==========================
* 6) Table 1 (levels): Overall sample (JIE-like stats)
*   列顺序：Obs, Mean, SD, p25, Median, p75, Min, Max
*==========================
eststo clear
estpost tabstat `VARS_LVL', statistics(n mean sd p25 p50 p75 min max) columns(statistics)

local t1_caption  "Descriptive statistics (overall sample)"
local t1_label    "tab:desc_overall"
local t1_notes1   "Sample restricted to CIC2 industries 17, 18, 19, 39, 40, and 41."
local t1_notes2   "Monetary variables are reported in levels as recorded; see Appendix for log-variable statistics if needed."
local t1_notes3   "Wage per worker equals wage bill divided by employment."
local t1_notes4   "Statistics are computed variable-wise using available observations."

esttab using "Table1_desc.tex", replace booktabs ///
    title("`t1_caption'") ///
    cells("n(fmt(0)) mean(fmt(3)) sd(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    collabels("Obs" "Mean" "SD" "p25" "Median" "p75" "Min" "Max") ///
    label nonumber nomtitle alignment(D) compress ///
    addnotes("`t1_notes1'" "`t1_notes2'" "`t1_notes3'" "`t1_notes4'")

*==========================
* 7) Table 2 (levels): By ownership
*   每个 ownership 列内包含 Obs、Mean、SD（JIE 常见分组表法）
*==========================
eststo clear
estpost tabstat `VARS_LVL', by(own3) statistics(n mean sd) columns(statistics)

local t2_caption  "Descriptive statistics by ownership"
local t2_label    "tab:desc_ownership"
local t2_notes1   "Ownership groups are classified as State-owned, Private, and Foreign-invested based on registry codes (or labeled firm type when registry codes are unavailable)."
local t2_notes2   "Variables are reported in levels; see Appendix for log-variable statistics if needed."
local t2_notes3   "Statistics are computed within each ownership group."

esttab using "Table2_byOwnership.tex", replace booktabs ///
    title("`t2_caption'") ///
    mtitle("State-owned" "Private" "Foreign-invested") ///
    unstack collabels("Obs" "Mean" "SD") ///
    cells("n(fmt(0)) mean(fmt(3)) sd(fmt(3))") ///
    label nonumber alignment(D) compress ///
    addnotes("`t2_notes1'" "`t2_notes2'" "`t2_notes3'")

*==========================
* 8) [Optional Appendix] Log-variable tables
*==========================
if `MAKE_APPENDIX_LOGS' {
    * A1: overall (logs)
    eststo clear
    estpost tabstat `VARS_LOG', statistics(n mean sd p25 p50 p75 min max) columns(statistics)

    local a1_caption "Appendix: Descriptive statistics (log variables, overall sample)"
    esttab using "App_TableA1_desc_logs.tex", replace booktabs ///
        title("`a1_caption'") ///
        cells("n(fmt(0)) mean(fmt(3)) sd(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3)) min(fmt(3)) max(fmt(3))") ///
        collabels("Obs" "Mean" "SD" "p25" "Median" "p75" "Min" "Max") ///
        label nonumber nomtitle alignment(D) compress

    * A2: by ownership (logs)
    eststo clear
    estpost tabstat `VARS_LOG', by(own3) statistics(n mean sd) columns(statistics)

    local a2_caption "Appendix: Descriptive statistics by ownership (log variables)"
    esttab using "App_TableA2_byOwnership_logs.tex", replace booktabs ///
        title("`a2_caption'") ///
        mtitle("State-owned" "Private" "Foreign-invested") ///
        unstack collabels("Obs" "Mean" "SD") ///
        cells("n(fmt(0)) mean(fmt(3)) sd(fmt(3))") ///
        label nonumber alignment(D) compress
}

display as text "LaTeX tables written:"
display as text " - Table1_desc.tex"
display as text " - Table2_byOwnership.tex"
if `MAKE_APPENDIX_LOGS' {
    display as text " - App_TableA1_desc_logs.tex"
    display as text " - App_TableA2_byOwnership_logs.tex"
}
