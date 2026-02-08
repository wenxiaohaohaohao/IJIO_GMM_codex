****************************************************
* Descriptive statistics (JIE-style) for six industries
* Output:
*   - Table1_desc.tex           (overall sample)
*   - Table2_byOwnership.tex    (SOE vs Private vs Foreign)
****************************************************

clear all
set more off

*---------------------------
* 0) Load & keep six CIC2
*---------------------------
use "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\Non_hicks\firststage.dta", clear
keep if inlist(cic2,17,18,19,39,40,41)



*---------------------------
* 1) Variable labels (English)
*---------------------------
capture label var K          "Capital stock (K)"
capture label var L          "Employment (L)"
capture label var MI         "Intermediate inputs (M, domestic)"
capture label var importint  "Imported inputs (X)"
capture label var R          "Revenue (R, current prices)"
capture label var Q          "Real output (Q)"
capture label var WL         "Wage bill"
capture label var Mana       "Management fees"
capture label var age        "Firm age (years)"
capture label var firmtype   "Ownership (registry type)"
capture label var cic2       "Industry (2-digit CIC)"
capture label var city       "City"

*---------------------------
* 2) Ownership trichotomy: own3 = {1 SOE, 2 Private, 3 Foreign}
*    优先用 regist；若没有则回退到 firmtype（中文标签）
*---------------------------
capture drop own3
gen own3 = .

capture confirm variable regist
if !_rc {
    * >>> 请按你数据编码细化；下列仅作通用示例 <<<
    replace own3 = 1 if inlist(regist,110,141,143,151)                       // State-owned (incl. collectively owned if适用)
    replace own3 = 2 if inlist(regist,150,159,160,170,171,172,173,174)        // Private
    replace own3 = 3 if inrange(regist,200,340)                               // Foreign/HMT + foreign-invested
}
else {
    capture confirm variable firmtype
    if !_rc {
        decode firmtype, gen(_firmtype_txt)
        replace own3 = 1 if regexm(_firmtype_txt, "国有|国有独资|集体")
        replace own3 = 2 if regexm(_firmtype_txt, "私营|民营|股份|有限责任")
        replace own3 = 3 if regexm(_firmtype_txt, "外商|外资|合资|合作|港澳台")
    }
}

label define own3 1 "State-owned" 2 "Private" 3 "Foreign-invested"
label values own3 own3

*---------------------------
* 3) Construct logs / derived vars
*---------------------------
capture drop lnk lnl lnm lnx lnr lnq lnage lnmana lnwl
gen lnk    = ln(K)                if K>0
gen lnl    = ln(L)                if L>0
gen lnm    = ln(MI)               if MI>0
gen lnx    = ln(importint)        if importint>0
gen lnr    = ln(R)                if R>0
gen lnq    = ln(Q)                if Q>0

gen lnwl   = ln(WL/L)             if WL>0 & L>0     // log wage per worker

label var lnk    "log Capital (K)"
label var lnl    "log Employment (L)"
label var lnm    "log Domestic inputs (M)"
label var lnx    "log Imported inputs (X)"
label var lnr    "log Revenue (R)"
label var lnq    "log Real output (Q)"
label var lnage  "log Firm age"
label var lnmana "log Management fees"
label var lnwl   "log Wage per worker"

* 供表用的变量清单（可按需增减）
local VARS  K L MI importint R Q WL age Mana ///
            lnk lnl lnm lnx lnr lnq lnwl lnage lnmana

*---------------------------
* 4) Install estout if needed
*---------------------------
cap which estpost
if _rc ssc install estout, replace

*---------------------------
* 5) Table 1: Overall sample (JIE-like stats)
*---------------------------
eststo clear
estpost tabstat `VARS', statistics(n mean sd p25 p50 p75 min max) columns(statistics)

local t1_caption  "Descriptive statistics (overall sample)"
local t1_label    "tab:desc_overall"
local t1_notes1   "Sample restricted to CIC2 industries 17, 18, 19, 39, 40, and 41."
local t1_notes2   "All monetary variables are in levels as recorded in the source files; logs are reported only for strictly positive observations."
local t1_notes3   "Wage per worker equals wage bill divided by employment; its logarithm is denoted by \textit{log Wage per worker}."
local t1_notes4   "Statistics are computed variable-wise using available observations."

esttab using "Table1_desc.tex", replace booktabs ///
    title("`t1_caption'") ///
    cells("n(fmt(0)) mean(fmt(3)) sd(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    varlabels(`VARLAB') ///
    nonumber nomtitle alignment(D) compress ///
    addnotes("`t1_notes1'" "`t1_notes2'" "`t1_notes3'" "`t1_notes4'")

*---------------------------
* 6) Table 2: By ownership (SOE / Private / Foreign-invested)
*     - Report Mean & SD for each group (JIE常见分组表)
*---------------------------
eststo clear
estpost tabstat `VARS', by(own3) statistics(mean sd) columns(statistics)

local t2_caption  "Descriptive statistics by ownership"
local t2_label    "tab:desc_ownership"
local t2_notes1   "Ownership groups are classified as State-owned, Private, and Foreign-invested based on registry codes (or labeled \texttt{firmtype} when registry codes are unavailable)."
local t2_notes2   "See Table~\\ref{tab:desc_overall} for variable definitions; logs are computed for strictly positive observations only."
local t2_notes3   "Statistics are computed within each ownership group."

esttab using "Table2_byOwnership.tex", replace booktabs ///
    title("`t2_caption'") ///
    mtitle("State-owned" "Private" "Foreign-invested") ///
    unstack collabels("Mean" "SD") ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    varlabels(`VARLAB') ///
    nonumber alignment(D) compress ///
    addnotes("`t2_notes1'" "`t2_notes2'" "`t2_notes3'")


display as text "LaTeX tables written: Table1_desc.tex, Table2_byOwnership.tex"
