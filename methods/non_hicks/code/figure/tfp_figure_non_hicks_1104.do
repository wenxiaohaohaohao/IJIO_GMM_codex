clear all
set more off
capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"


*******************************************************************************
//鐩存帴璁＄畻omega
*******************************************************************************
use "$DATA_WORK/firststage-nonhicks.dta",clear

* 3) 鍚堝苟"鍚勮涓氭渶缁堢郴鏁?
merge m:1 cic2 using "$RES_DATA/gmm_point_industry.dta", keep(match) nogen
* 1) 甯告暟
capture confirm variable const
if _rc gen byte const = 1

* 2) 鎺у埗椤硅础鐚細age + 鎵€鏈夊埗(澶栦紒/姘戜紒锛涘熀绫?鍥戒紒)
gen double ctrl_hat = 0

capture confirm variable b_lnage
if !_rc replace ctrl_hat = ctrl_hat + b_lnage * lnage

foreach c in 2 3 {
    capture confirm variable firmcat_`c'
    if !_rc {
        capture confirm variable b_firmcat_`c'
        if !_rc replace ctrl_hat = ctrl_hat + b_firmcat_`c' * firmcat_`c'
    }
}

* 3) 鐢熶骇椤硅础鐚細甯告暟 + L + K + M + S^2锛坋s 涓?es2q锛?gen double prod_hat = b_const*const ///
                    + b_l*l + b_k*k + b_m*m + b_es*es + b_essq*es2q

* 4) 澶栨帹 \hat{omega} 锛歱hi - 鐢熶骇椤?- 鎺у埗椤?capture drop omega_hat
gen double omega_hat = phi - prod_hat - ctrl_hat
label var omega_hat "DLW omega (extrapolated; controls: age+ownership)"
label var ctrl_hat  "contrib(age, firmcat_2, firmcat_3)"
label var prod_hat  "contrib(const+L+K+M+S^2)"

save "$DATA_WORK/omega_spliced_2000_2007.dta",replace

* 鍏堢‘璁ゆ椂闂磋瀹?xtset firmid year
*******************************  绠€鍗曞钩鍧囷紝娌℃湁鏉冮噸unweight ********************************************
* 鎸夊勾鍙栧潎鍊硷紙涓嶅垎琛屼笟锛?collapse (mean) mean_tfp=omega_hat (sd) sd_tfp=omega_hat (count) N=omega_hat, by(year)

list year mean_tfp sd_tfp N

* 绠€鍗曟姌绾垮浘
twoway line mean_tfp year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average TFP") xtitle("Year") ///
    title("Annual Average TFP (All Industries)") ///
    legend(off)

* 鏋勯€犲潎鍊?卤 1.96*SE
gen se_tfp = sd_tfp/sqrt(N)
gen lb = mean_tfp - 1.96*se_tfp
gen ub = mean_tfp + 1.96*se_tfp

* 鎶樼嚎 + 闃村奖
twoway (rarea ub lb year, color(gs12%40)) ///
       (line mean_tfp year, lcolor(navy) lwidth(medthick)), ///
       ytitle("Average TFP") xtitle("Year") ///
       title("Annual Average TFP with 95% CI") legend(off)

******************************************************************************
******************************************************************************
*****************************Non_Hicks tech************************************
******************************************************************************
******************************************************************************

use "$DATA_WORK/mdnon-Hicks.dta", clear   

*******************************  绠€鍗曞钩鍧囷紝娌℃湁鏉冮噸unweight ********************************************
* 鎸夊勾鍙栧潎鍊硷紙涓嶅垎琛屼笟锛?collapse (mean) mean_aft=aft (sd) sd_aft=aft (count) N=aft, by(year)

list year mean_aft sd_aft N

* 绠€鍗曟姌绾垮浘
twoway line mean_aft year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average AFT") xtitle("Year") ///
    title("Annual Average AFT (All Industries)") ///
    legend(off)

* 鏋勯€犲潎鍊?卤 1.96*SE
gen se_aft = sd_aft/sqrt(N)
gen lb = mean_aft - 1.96*se_aft
gen ub = mean_aft + 1.96*se_aft

* 鎶樼嚎 + 闃村奖
twoway (rarea ub lb year, color(gs12%40)) ///
       (line mean_aft year, lcolor(navy) lwidth(medthick)), ///
       ytitle("Average AFT") xtitle("Year") ///
       title("Annual Average AFT with 95% CI") legend(off)

*********************************鏈夋潈閲嶇殑 tfp*********************************

use "$DATA_WORK/omega_spliced_2000_2007.dta", clear

tempfile tfp
save "`tfp'", replace

use "$DATA_WORK/firststage-nonhicks.dta", clear

keep firmid year cic2 R
tempfile weights_R
save "`weights_R'", replace

* 1. 褰撳勾鎬绘潈閲?bys year: egen Rtot = total(R)

* 2. 琛屼笟浠介
gen share = R/Rtot

* 鍥炲埌 TFP锛屽悎骞?R
use "`tfp'", clear
merge 1:1 firmid year cic2 using "`weights_R'", nogen keep(match)

*--------------------------------------------------------------*
* 2. 浼佷笟 鈫?琛屼笟脳骞翠唤锛氱敤 R 鍋氬姞鏉冨潎鍊?*   涓ょ鍐欐硶閮借锛歝ollapse + [aw=R]锛涙垨鍏堢畻浠介鍐嶅姞鎬?*   杩欓噷鐢?collapse锛堟洿绠€娲侊級
*--------------------------------------------------------------*
* 鐩存帴浼佷笟灞傞潰鑱氬悎鍒板勾搴?collapse (mean) tfp_year = omega_hat [aw=R], by(year)

list year tfp_year 

* 绠€鍗曟姌绾垮浘
twoway line tfp_year year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average TFP weighted ") xtitle("Year") ///
    title("Annual Average TFP weighted (All Industries)") ///
    legend(off)

*********************************鏈夋潈閲嶇殑 aft*********************************
use "$DATA_WORK/mdnon-Hicks.dta", clear   
* 鐩存帴浼佷笟灞傞潰鑱氬悎鍒板勾搴?collapse (mean) aft_year = aft [aw=R], by(year)

list year aft_year

*--------------------------------------------------------------*
* 绠€鍗曟姌绾垮浘
*--------------------------------------------------------------*
twoway line aft_year year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average AFT weighted") xtitle("Year") ///
    title("Annual Average AFT weighted (All Industries)") ///
    legend(off)
	
preserve 

collapse (median) aft_year = aft, by(year)

list year aft_year

*--------------------------------------------------------------*
* 绠€鍗曟姌绾垮浘
*--------------------------------------------------------------*
twoway line aft_year year, ///
    lcolor(blue) lwidth(medthick) ///
    ytitle("Average AFT weighted") xtitle("Year") ///
    title("Annual Average AFT weighted (All Industries)") ///
    legend(off)

restore

*******************************鏀惧湪涓€璧?********************************

********************************************************************************
* 鐩爣锛歍FP 涓?AFT锛圧 鍔犳潈锛夊悓鍥撅紱鍚勮嚜鎸?2000=1"锛岃嫢璇ュ簭鍒楃己 2000 鐢ㄨ嚜韬渶鏃╁勾銆?*       鑻ュ熀鏈?鈮?0 鎴栨帴杩?0锛屽垯閲囩敤"宸姣斾緥"褰掍竴鍖栵紝闃叉褰㈢姸琚瘮鍊兼壄鏇层€?********************************************************************************

********************************* TFP锛堝姞鏉冿級 *********************************
use "$DATA_WORK/omega_spliced_2000_2007.dta", clear
tempfile tfp
save "`tfp'", replace

use "$DATA_WORK/firststage-nonhicks.dta", clear
keep firmid year cic2 R
tempfile weights_R
save "`weights_R'", replace

* 鍚堝苟 R 鍒?TFP
use "`tfp'", clear
merge 1:1 firmid year cic2 using "`weights_R'", nogen keep(match)

* 纭繚 year 涓烘暟鍊?capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,") force

* 浼佷笟 鈫?骞村害锛圧 鍔犳潈锛?collapse (mean) tfp_year = omega_hat [aw=R], by(year)
tempfile tfp_year
save "`tfp_year'", replace

********************************* AFT锛堝姞鏉冿級 *********************************
use "$DATA_WORK/mdnon-Hicks.dta", clear
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,") force

collapse (mean) aft_year = aft [aw=R], by(year)
tempfile aft_year
save "`aft_year'", replace

************************* 鍚堝埌涓€寮犺〃锛堜粎涓轰綔鍥炬柟渚匡級 *************************
use "`tfp_year'", clear
merge 1:1 year using "`aft_year'", nogen
sort year

* 閫夋嫨鍚勮嚜鍩烘湡锛堜紭鍏?2000锛屽惁鍒欒搴忓垪鏈€鏃╁勾锛?local basewant = 2000

* 鈥斺€?TFP 鍩烘湡
local base_tfp = `basewant'
quietly count if year==`base_tfp' & !missing(tfp_year)
if (r(N)==0) {
    quietly summarize year if !missing(tfp_year), meanonly
    local base_tfp = r(min)
    di as txt "TFP锛?000 涓嶅湪鏍锋湰锛屾敼鐢ㄦ渶鏃╁勾浠?" as res `base_tfp' as txt " 浣滀负鍩烘湡銆?
}
quietly summarize tfp_year if year==`base_tfp', meanonly
scalar b_tfp = r(mean)

* 鈥斺€?AFT 鍩烘湡
local base_aft = `basewant'
quietly count if year==`base_aft' & !missing(aft_year)
if (r(N)==0) {
    quietly summarize year if !missing(aft_year), meanonly
    local base_aft = r(min)
    di as txt "AFT锛?000 涓嶅湪鏍锋湰锛屾敼鐢ㄦ渶鏃╁勾浠?" as res `base_aft' as txt " 浣滀负鍩烘湡銆?
}
quietly summarize aft_year if year==`base_aft', meanonly
scalar b_aft = r(mean)

di as txt "鍩烘湡妫€鏌ワ細 TFP base=" as res %9.4g b_tfp ///
           as txt "  |  AFT base=" as res %9.4g b_aft

********************************************************************************
* 绋冲仴褰掍竴鍖栵細鍩烘湡>0 鐢ㄦ瘮鍊硷紱鍩烘湡<0 鐢ㄥ樊棰濇瘮渚嬶紱鍩烘湡=0 鐢ㄦ爣鍑嗗樊鍋氬昂搴?********************************************************************************

* 鈥斺€?鍏堟竻鐞嗘棫鍙橀噺
capture drop tfp_index aft_index
gen double tfp_index = exp(tfp_year - b_tfp)
gen double aft_index = exp(aft_year - b_aft)

label var tfp_index "TFP index (base=`base_tfp' 鈫?1)"
label var aft_index "AFT index (base=`base_aft' 鈫?1)"

save "$RES_DATA/tfp_aft_annual_rate.dta", replace

********************************************************************************
* 浣滃浘锛堝悓杞村姣旓級
********************************************************************************

twoway ///
  (connected tfp_index year, lcolor(blue) lpattern(solid) lwidth(medium) ///
      msymbol(O) mcolor(blue) mfcolor(none) msize(medlarge) sort) ///
  (connected aft_index year,  lcolor(red)  lpattern(dash)  lwidth(medium) ///
      msymbol(O) mcolor(red)  mfcolor(none) msize(medlarge) sort), ///
  legend(order(1 "TFP" 2 "AFT") position(6) ring(1) cols(2) region(lstyle(none))) ///  
  ytitle("Index (each series normalized to its own base; base=1)") ///
  xtitle("Year") ///
  title("TFP vs AFT (R-weighted, robust normalization)") ///
  xlabel(2000(1)2007, grid) ///
  xscale(range(2000 2007)) ///
  ylabel(, grid) ///
 graphregion(color(white) lstyle(solid) lcolor(black)) ///
  plotregion(fcolor(white) lstyle(solid) lcolor(black))

* 鍙€夊鍑?graph export "$RES_FIG/tfp_aft_index_weighted.png", replace width(1200)

use "$RES_DATA/tfp_aft_annual_rate.dta", clear
* TFP
sum tfp_index if year==2000
scalar tfp0 = r(mean)
sum tfp_index if year==2007
scalar tfp7 = r(mean)

scalar tfp_cagr = (tfp7/tfp0)^(1/7) - 1
display "TFP 骞村潎澧為暱鐜?= " 100*tfp_cagr "%"

* AFT
sum aft_index if year==2000
scalar aft0 = r(mean)
sum aft_index if year==2007
scalar aft7 = r(mean)

scalar aft_cagr = (aft7/aft0)^(1/7) - 1
display "AFT 骞村潎澧為暱鐜?= " 100*aft_cagr "%"

************************************************************************
*********************鍒嗚涓氱殑骞村钩鍧囧闀跨巼*************************************************************************************************************
/*******************************************************************************
* 鍒嗚涓氾紙cic2锛夌殑骞村潎澧為暱鐜囷細TFP 涓?AFT
* 闇€姹傦細浣跨敤涓庡墠鏂囩浉鍚屼袱浠?浼佷笟灞傞潰"鍘熷鏁版嵁 + 鏀跺叆鏉冮噸 R
*******************************************************************************/

*--- 1) 鍑嗗锛氫粠浼佷笟灞傞潰鑱氬悎鍒?琛屼笟脳骞翠唤锛堟潈閲?R锛?------------------------*
* TFP锛氱敤浣犱箣鍓嶇殑鏁版嵁婧愶紙鍚?omega_hat, firmid, cic2, year, R锛?preserve
    use "$DATA_WORK/omega_spliced_2000_2007.dta", clear
    merge 1:1 firmid year cic2 using "$DATA_WORK/firststage-nonhicks.dta", ///
        keepusing(R) nogen keep(match)
    drop if missing(omega_hat, R, cic2, year) | R<=0
    collapse (mean) tfp_ln = omega_hat [aw=R], by(cic2 year)   // 琛屼笟脳骞?鍔犳潈鍧囧€硷紙瀵规暟锛?    tempfile tfp_cy
    save "`tfp_cy'", replace
restore

* AFT锛氱敤 mdnon-Hicks 婧愶紙鍚?aft, firmid, cic2, year, R锛?preserve
    use "$DATA_WORK/mdnon-Hicks.dta", clear
    drop if missing(aft, R, cic2, year) | R<=0
    collapse (mean) aft_ln = aft [aw=R], by(cic2 year)         // 琛屼笟脳骞?鍔犳潈鍧囧€硷紙瀵规暟锛?    tempfile aft_cy
    save "`aft_cy'", replace
restore

* 鍚堝苟鍒板悓涓€寮犺涓毭楀勾琛?use "`tfp_cy'", clear
merge 1:1 cic2 year using "`aft_cy'", nogen

*--- 2) 涓烘瘡涓涓氶€夋嫨鍩烘湡锛氫紭鍏?2000锛屽惁鍒欒琛屼笟鏈€鏃╁勾 ---------------------*
local basewant = 2000

bys cic2: egen first_year = min(year)
bys cic2: egen last_year  = max(year)

* 鍩烘湡骞翠唤锛堜紭鍏?000锛屽惁鍒欐渶鏃╁勾锛?bys cic2: egen base_year_tfp = max(cond(year==`basewant' & !missing(tfp_ln), year, .))
replace base_year_tfp = first_year if missing(base_year_tfp)

bys cic2: egen base_year_aft = max(cond(year==`basewant' & !missing(aft_ln), year, .))
replace base_year_aft = first_year if missing(base_year_aft)

* 鍩烘湡鐨勫鏁版按骞?bys cic2: egen tfp_base_ln = max(cond(year==base_year_tfp, tfp_ln, .))
bys cic2: egen aft_base_ln = max(cond(year==base_year_aft, aft_ln, .))

*--- 3) 琛屼笟鎸囨暟锛堝熀鏈?1锛夛細exp(ln_t - ln_base) -------------------------------*
gen double tfp_index_cy = exp(tfp_ln - tfp_base_ln) if !missing(tfp_ln, tfp_base_ln)
gen double aft_index_cy = exp(aft_ln - aft_base_ln) if !missing(aft_ln, aft_base_ln)

label var tfp_index_cy "TFP index by sector-year (base=1)"
label var aft_index_cy "AFT index by sector-year (base=1)"

*--- 4) 琛屼笟骞村潎澧為暱鐜囷紙CAGR锛夛細浠ュ悇鑷熀鏈熲啋鏈湡 ------------------------------*
* 骞存暟锛堟湯鏈?鍩烘湡锛?gen years_tfp = last_year - base_year_tfp
gen years_aft = last_year - base_year_aft

* 鏈湡鎸囨暟锛?璇ヨ涓氭渶鍚庝竴骞达級
bys cic2: egen tfp_last = max(cond(year==last_year, tfp_index_cy, .))
bys cic2: egen aft_last = max(cond(year==last_year, aft_index_cy, .))

* CAGR锛?(last/base)^(1/years)-1锛沚ase=1 鏁呬负 last^(1/years)-1
gen double tfp_cagr = tfp_last^(1/years_tfp) - 1 if years_tfp>0 & tfp_last>0
gen double aft_cagr = aft_last^(1/years_aft) - 1 if years_aft>0 & aft_last>0

*--- 5) 閫愬勾瀵规暟澧為€熺殑琛屼笟鍧囧€硷紙鍋氫氦鍙夋牎楠岋紝鍙笌 CAGR 瀵圭収锛?------------------*
xtset cic2 year, yearly
gen double dlog_tfp = tfp_ln - L.tfp_ln if !missing(tfp_ln, L.tfp_ln)
gen double dlog_aft = aft_ln - L.aft_ln if !missing(aft_ln, L.aft_ln)

bys cic2: egen mean_dlog_tfp = mean(dlog_tfp)
bys cic2: egen mean_dlog_aft = mean(dlog_aft)

*--- 6) 杈撳嚭琛屼笟灞傞潰鐨勭粨鏋滆〃 --------------------------------------------------*
preserve
    keep cic2 base_year_tfp last_year years_tfp tfp_cagr mean_dlog_tfp ///
         base_year_aft last_year years_aft aft_cagr mean_dlog_aft
    bys cic2: keep if _n==1

    gen tfp_cagr_pct = 100*tfp_cagr
    gen aft_cagr_pct = 100*aft_cagr
    gen mean_tfp_pct = 100*(exp(mean_dlog_tfp)-1)
    gen mean_aft_pct = 100*(exp(mean_dlog_aft)-1)

    order cic2 base_year_tfp last_year years_tfp tfp_cagr tfp_cagr_pct mean_dlog_tfp mean_tfp_pct ///
                base_year_aft            years_aft aft_cagr aft_cagr_pct mean_dlog_aft mean_aft_pct

    label var tfp_cagr_pct "TFP CAGR (%)"
    label var aft_cagr_pct "AFT CAGR (%)"
    label var mean_tfp_pct "Mean annual % (from log)"
    label var mean_aft_pct "Mean annual % (from log)"

    * 鏌ョ湅 & 淇濆瓨
    list in 1/5, abbrev(16) noobs
    save "$RES_DATA/sector_cagr_tfp_aft.dta", replace
restore

di as txt "宸茬敓鎴愬垎琛屼笟骞村潎澧為暱鐜囩粨鏋滐細sector_cagr_tfp_aft.dta"

*--- 6) 绮剧畝杈撳嚭锛氬彧淇濈暀 cic2 + CAGR 鐧惧垎姣?-------------------------------*
use "$RES_DATA/sector_cagr_tfp_aft.dta", clear
preserve
    keep cic2 tfp_cagr_pct aft_cagr_pct
    bys cic2: keep if _n==1   // 姣忚涓氬彧鐣欎竴鏉?
    order cic2 tfp_cagr_pct aft_cagr_pct
    label var tfp_cagr_pct "TFP CAGR (%)"
    label var aft_cagr_pct "AFT CAGR (%)"

    * 娴忚鍓?0涓涓?    list in 1/6, abbrev(16) noobs

    * 淇濆瓨绮剧畝缁撴灉
    save "$RES_DATA/sector_cagr_tfp_aft_slim.dta", replace
restore

di as txt "绮剧畝鐗堢粨鏋滃凡淇濆瓨锛歴ector_cagr_tfp_aft_slim.dta"
use "$RES_DATA/sector_cagr_tfp_aft_slim.dta", clear


