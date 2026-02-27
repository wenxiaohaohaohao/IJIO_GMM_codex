*******************************************************
* bootstrap0901_group.do
* Usage:
*   do "$CODE/estimate/bootstrap0901_group.do"    // pooled {17,18,19}, IV spec of 18
*   do "$CODE/estimate/bootstrap0901_group.do"    // pooled {39,40,41}, IV spec of 40
* Outputs (per group):
*   - gmm_point_group_<GROUP>.dta   (point + bootstrap SEs + J + N)
*   - gmm_boot_group_<GROUP>.dta    (bootstrap draws)

* [瀹氫箟闃舵]  鍏堝畾涔夛細Mata鍑芥暟 + Stata鐨刾rogram  gmm2step_once
* [鎵ц闃舵]  for 姣忔bootstrap澶嶅埗锛?*              -> 璋?gmm2step_once (Stata)
*              -> 璋?mata:refresh_globals() (Mata)
*              -> 璋?mata:run_two_step()    (Mata, 鐪熸浼樺寲)
*              <- 缁撴灉鍥炲埌 Stata, 瀛樺叆 r()

*******************************************************
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


* === 浠呬粠鍏ㄥ眬璇诲彇缁勫悕锛屽苟鍋氭牎楠?===
if ("$GROUP_NAME"=="") {
    di as err "ERROR: global GROUP_NAME is empty. Set it before calling this do-file."
    exit 3499
}
if ("$GROUP_NAME"!="G1_17_19" & "$GROUP_NAME"!="G2_39_41") {
    di as err "ERROR: invalid GROUP_NAME=[$GROUP_NAME]. Must be G1_17_19 or G2_39_41."
    exit 3499
}

* 鍦ㄦ湰 do 鐨勪綔鐢ㄥ煙鍐呯敓鎴愪竴涓?local锛屼究浜庡悗闈㈡枃浠跺悕/绛涢€変娇鐢?local GROUPNAME "$GROUP_NAME"
di as txt "DBG: GROUP_NAME(global) = [$GROUP_NAME] ; GROUPNAME(local) = `GROUPNAME'"

* -------- Load & merge -------- *
use "$DATA_RAW/junenewg_0902", clear

* -------- Group filter (by GROUPNAME) -------- *
if ("`GROUPNAME'"=="G1_17_19") {
    keep if inlist(cic2,17,18,19)
}
else if ("`GROUPNAME'"=="G2_39_41") {
    keep if inlist(cic2,39,40,41)
}
else {
    di as err "Unknown GROUPNAME=`GROUPNAME'. Must be G1_17_19 or G2_39_41."
    exit 198
}

duplicates drop firmid year, force

* year numeric
 confirm numeric variable year
if _rc destring year, replace ignore(" -/,")
xtset firmid year

// ===== 浣犵殑鏁版嵁澶勭悊涓庢瀯閫犻儴鍒?====
gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

drop if domesticint <= 0
drop if 钀ヤ笟鏀跺叆鍚堣鍗冨厓 < 40

gen double R = 宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓 * 1000 / e

rename 鍥哄畾璧勪骇鍚堣鍗冨厓 K
drop if K < 30
rename 鍏ㄩ儴浠庝笟浜哄憳骞村钩鍧囦汉鏁颁汉 L
replace L = 骞存湯浠庝笟浜哄憳鍚堣浜?if year==2003
drop if L < 8

rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

gen double WL = 搴斾粯宸ヨ祫钖叕鎬婚鍗冨厓 * 1000 / e

* 鐢熸垚浼佷笟鎬ц川澶х被鍙橀噺
gen firmcat = . 

* 1 鏄浗浼?replace firmcat = 1 if firmtype == 1

* 2銆?銆? 鏄浼?replace firmcat = 2 if inlist(firmtype, 2, 3, 4)

* 鍏朵粬锛堝嵆闈?1銆?銆?銆?锛夋槸绉佷紒
replace firmcat = 3 if missing(firmcat)

* 娣诲姞鏍囩
label define firmcatlbl 1 "鍥戒紒" 2 "澶栦紒" 3 "绉佷紒", replace
label values firmcat firmcatlbl
* -------- 2) 鐢熸垚铏氭嫙鍙橀噺锛堝熀鍑嗭細鍥戒紒锛?-------

tab firmcat, gen(firmcat_)

* 妫€鏌ュ垎绫荤粨鏋?tab firmcat

 confirm variable firmtotalq
if !_rc rename firmtotalq X

* Merge investment deflator and reconstruct capital
merge m:1 year using "$DATA_RAW/Brandt-Rawski investment deflator.dta", nogen
replace BR_deflator = 116.7 if year == 2007
drop if year < 2000

bysort firmid (year): gen double I = K - K[_n-1]
bysort firmid (year): replace I = K if _n == 1

bysort firmid (year): gen double inv0 = I
replace inv0 = 0 if missing(inv0)
forvalues v = 1/19 {
    bysort firmid (year): gen double inv`v' = I[_n-`v'] * (BR_deflator / BR_deflator[_n-`v']) if _n > `v'
    replace inv`v' = 0 if missing(inv`v')
}
gen double K_current = inv0
forvalues v = 1/19 {
    replace K_current = K_current + inv`v'
}
drop inv0-inv19
replace K = K_current

rename 宸ヤ笟涓棿鎶曞叆鍚堣鍗冨厓 MI
rename 绠＄悊璐圭敤鍗冨厓 Mana

gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0
capture ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen double lratiofs = lnR - lnM

gen ratio = importint/(domesticint+importint)
*drop if ratio<0.01   
*drop if ratio>0.98

gen inputp = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF = importint/einputp

replace 寮€涓氭垚绔嬫椂闂村勾 = . if 寮€涓氭垚绔嬫椂闂村勾==0
gen age   = year - 寮€涓氭垚绔嬫椂闂村勾 + 1
gen lnage = ln(age)
gen lnmana = ln(Mana)

gen  l  = ln(L)
gen  lsq = l*l 
gen double k  = ln(K)
gen  ksq = k*k  
gen double q  = ln(Q)
gen m = ln(delfateddomestic)        
gen double x  = ln(X)
gen double r  = ln(R)
gen DWL=WL/L
gen wl=ln(DWL)

winsor2 k, cuts(1 99) by(cic2 year) replace
winsor2 l, cuts(1 99) by(cic2 year) replace
xtset firmid year

capture confirm variable pft
if !_rc rename pft pi
capture confirm variable foreignprice
if !_rc rename foreignprice WX
capture confirm variable WX
if !_rc gen double wx = ln(WX)

* First stage  (ADD tariff as you asked)(鍏堟妸鍏崇◣鍒犻櫎鎺夛紝涔嬪悗鍐嶈)
reg lratiofs k l wl x age lnmana i.firmcat i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2

* phi cubic 
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmcat i.city i.year
// 鍥炲綊锛堜綘鐨勭涓€闃舵锛夊悗锛氶娴嬪悗鍙鏈夋晥鏍锋湰璧嬪€?predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "$DATA_WORK/firststage.dta", replace

**鍒犻€夎繛缁?= 2鐨勫叕鍙革紝浠ュ強鍒犻櫎棣栧勾涓嶄繚鐣欙紙鍥犱负鍚庨潰鏈塴ag锛?* 1. 鎸夊叕鍙窱D鍜屽勾浠芥帓搴?sort firmid year

* 楠岃瘉鏁版嵁鍞竴鎬?isid firmid year, sort
di "鉁?Data sorted and verified: unique firm-year combinations"

* 2. 璁＄畻骞翠唤闂撮殧
by firmid: gen gap = year - L.year

* 3. 璇嗗埆杩炵画娈?by firmid: gen seqblock = (gap != 1 | missing(gap))
by firmid: replace seqblock = sum(seqblock)

* 4. 璁＄畻姣忎釜杩炵画娈电殑闀垮害
bys firmid seqblock: gen seg_len = _N

* 5. 璁＄畻姣忓鍏徃鐨勬渶闀胯繛缁闀垮害
bys firmid: egen max_seg_len = max(seg_len)

* 6. 鍙繚鐣欐渶闀胯繛缁鈮?骞寸殑鍏徃锛堜繚鐣欒繖浜涘叕鍙哥殑鎵€鏈夎娴嬶級
keep if max_seg_len >= 2

* 7. 鍒犻櫎杈呭姪鍙橀噺
drop gap seqblock seg_len max_seg_len

* 8. 楠岃瘉缁撴灉
bys firmid: gen nobs_firm = _N
tab nobs_firm, missing
sum nobs_firm, detail
drop nobs_firm

*鐢熸垚婊炲悗椤?
isid firmid year, sort
xtset firmid year
gen double phi_lag = L.phi

gen double klag = L.k
gen double mlag = L.m
gen double xlag = L.x
gen double llag = L.l
gen double ksqlag = L.ksq
gen double lsqlag = L.lsq

gen double llagsq = llag^2
gen double klagsq = klag^2
gen double mlagsq = mlag^2
gen double xlagsq = xlag^2

gen double llagklag = llag*klag
gen double llagmlag = llag*mlag
gen double llagxlag = llag*xlag
gen double klagmlag = klag*mlag
gen double klagxlag = klag*xlag
gen double mlagxlag = mlag*xlag

gen double llag2 = L2.l
* optional interactions used elsewhere
gen double llagk = llag*k
gen double mlagl = mlag*l
gen double mlagxlagk = mlagxlag*k
gen double xlagk = xlag*k
gen double mlagk = mlag*k
gen double mlagllag = mlag*llag
gen double llagxlagmlag = llagxlag*mlag
gen double xlagllag = xlag*llag
gen double xllagl = xlag*l

gen double lages   = L.es
gen double lages2q = L.es2q
gen double klages=k*lages

gen double kl = k*l
gen byte   const = 1

capture confirm variable const
if _rc gen byte const = 1
order firmid year, first

******************宸ュ叿鍙橀噺鍑嗗*********
* 棣栧厛锛屼负姣忎釜鍐呯敓鍙橀噺鍒涘缓涓€涓复鏃舵爣璇?gen temp_l = l
gen temp_k = k
gen temp_m = m

* 浣跨敤 rangestat 鍛戒护锛堥渶瑕佸厛瀹夎锛歴sc install rangestat锛?* 璁＄畻鍚岃涓?cic2)鍚屽勾浠?year)涓嬶紝闄よ嚜宸卞鐨勫潎鍊?capture ssc install rangestat
rangestat (mean) temp_l, by(cic2 year) interval(firmid . .) excludeself
rename temp_l_mean l_ind_yr // 琛屼笟-骞村害鍔冲姩鍧囧€?
rangestat (mean) temp_k, by(cic2 year) interval(firmid . .) excludeself
rename temp_k_mean k_ind_yr // 琛屼笟-骞村害璧勬湰鍧囧€?
rangestat (mean) temp_m, by(cic2 year) interval(firmid . .) excludeself
rename temp_m_mean m_ind_yr // 琛屼笟-骞村害m鍧囧€?
* 娓呯悊涓存椂鍙橀噺
drop temp_*
********************************
* 鍏崇◣鍜屽埗搴︾殑IV
merge m:1 firmid year using "$DATA_RAW/firm_year_IVs_Ztariff_ZHHI.dta"
keep if _merge==3
drop if missing(Z_tariff, Z_HHI_post)
********************************
* Year dummies (baseline = first year in sample)
levelsof year, local(yrs)
local base : word 1 of `yrs'
quietly tab year, gen(Dy)
local j = 1
foreach y of local yrs {
    if `y' == `base' drop Dy`j'
    else               rename Dy`j' dy`y'
    local ++j
}

isid firmid year, sort
xtset firmid year

* 鈥斺€?1) 骞撮緞鐨勬粸鍚?鈥斺€?
capture confirm variable lnagelag
if _rc {
    gen double lnagelag = L.lnage
    di "鉁?Created: lnagelag (lagged firm age)"
}

drop if missing(const, r, l, k, phi, phi_lag, llag, klag, mlag, lsqlag, ksqlag, ///
    lsq, ksq, m, es, es2q, lages, lages2q, lnage, firmcat, lnmana, ///
    lnagelag, firmcat_2, firmcat_3, dy2002-dy2007, klages, mlagxlag)
	
	* 鍏堝湪 Stata 閲屽垱寤哄崰浣嶅彉閲忥紝渚?Mata 鍐欏叆娈嬪樊 鈥斺€?120娣诲姞 鈥斺€?*
capture drop OMEGA2 XI2                 // 闃叉涔嬪墠宸叉湁鍚屽悕鍙橀噺 鈥斺€?120娣诲姞 鈥斺€?*
gen double OMEGA2 = .                   // 涓庢牱鏈鏁扮浉鍚岀殑绌哄垪 鈥斺€?120娣诲姞 鈥斺€?*
gen double XI2    = .                   // 鈥斺€?120娣诲姞 鈥斺€?*

* 浣跨敤 global 浼犻€掕捣鐐圭姸鎬侊紝渚?Mata 璇诲彇
  // 0=娌℃湁宸叉湁璧风偣锛?=宸叉湁鏀舵暃璧风偣  * 鈥斺€?120娣诲姞 鈥斺€?* 

 

local have_b0 0    
*==================== Mata (two-step GMM; add tariff to CONSOL) ====================*
mata:
mata clear

real scalar scalarmax(real scalar a, real scalar b)
{
    return( a > b ? a : b )
}

/* 鍒濆鍖栧叏灞€鐭╅樀锛堢敤浜?st_store 鍥炲啓鏃朵繚璇佸瓨鍦級 */

OMEGA2 = J(0,1,.)
XI2    = J(0,1,.)

void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init, Wg_opt
        
    printf(">>> CHECKPOINT A: starting refresh_globals()\n")
        
    X       = st_data(., ("const","l","k","lsq","ksq","m","es","es2q"))
    printf(">>> CHECKPOINT B: X loaded (%f rows)\n", rows(X))
        
    X_lag   = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag","lages","lages2q"))
    printf(">>> CHECKPOINT C: X_lag loaded (%f rows)\n", rows(X_lag))

    /* IV sets by group name*/
    string scalar g
    g = st_global("GROUP_NAME")
    printf(">> [Mata] GROUPNAME seen: [%s]\n", g)
    if (g!="G1_17_19" & g!="G2_39_41") {
        errprintf("Invalid GROUPNAME = [%s]; must be G1_17_19 or G2_39_41\n", g)
        _error(3499)
    }

    if (g=="G1_17_19") {
        // 鍘熷厛 anchor=18 鐨?IV
		Z = st_data(., ("const","lages","llag","klag", "mlag", "l_ind_yr","m_ind_yr", "k_ind_yr","Z_HHI_post"))   
        printf(">> Using IV: IV_anchor18_Kz9\n")
    }
    else  {
        // 鍘熷厛 anchor=40 鐨?IV
         Z = st_data(., ("llag","klag","l","lages","lsq", "l_ind_yr", "k_ind_yr", "m_ind_yr","Z_tariff", "Z_HHI_post"))
        printf(">> Using IV: IV_anchor40_Kz9\n")
    }

   /* ---------- 鏍囧噯鍖?Z ----------
    real rowvector mu, zs
    mu = colsum(Z) :/ rows(Z)                 // 鍒楀潎鍊?   Z  = Z :- mu                              // 闆跺潎鍊?    zs = sqrt(colsum(Z:^2) :/ rows(Z)) :+ 1e-12  // 鍒楃殑 L2 鏍囧害锛堝姞寰皬椤归槻 0锛?    Z  = Z :/ zs                              // 鍗曚綅灏哄害
    */       
    printf(">>> CHECKPOINT Z1: Z raw loaded (%f rows, %f cols)\n", rows(Z), cols(Z))

    // ========== 鈶?鍦ㄨ繖閲屾彃鍏?Z 鐨?missing 妫€鏌?==========
    real scalar z
    real rowvector Zmiss
    Zmiss = colmissing(Z)
    printf(">>> CHECKPOINT Z2: Z column missing counts = ")
    z = 1
    while (z <= cols(Z)) {
        printf("%f ", Zmiss[z])
        z = z + 1
    }
    printf("\n")
    // =================================================

    // ---------- 涓诲彉閲?----------
    PHI     = st_data(., "phi")
    printf(">>> CHECKPOINT E: PHI loaded (%f rows)\n", rows(PHI))
        
    PHI_lag = st_data(., "phi_lag")
    printf(">>> CHECKPOINT F: PHI_lag loaded (%f rows)\n", rows(PHI_lag))

    // ========== 鈶?PHI / PHI_lag missing 妫€鏌?==========
    printf(">>> PHI missing count = %f\n", colmissing(PHI)[1])
    printf(">>> PHI_lag missing count = %f\n", colmissing(PHI_lag)[1])
    // =================================================

    Y       = st_data(., "r")
    printf(">>> CHECKPOINT G: Y loaded (%f rows)\n", rows(Y))
    C       = st_data(., "const")
    printf(">>> CHECKPOINT H: C loaded (%f rows)\n", rows(C))

    // Controls锛堝悗缁瑕佸姞鍏崇◣鍐嶆斁杩涜繖閲岋級
    CONSOL  = st_data(., ("dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","lnage","firmcat_2","firmcat_3"))

    // ========== 鈶?鍦ㄨ繖閲屾彃鍏?CONSOL 鐨?missing 妫€鏌?==========
    real scalar j
    real rowvector Cmiss
    printf(">>> CHECKPOINT CONSOL rows=%f cols=%f\n", rows(CONSOL), cols(CONSOL))
    Cmiss = colmissing(CONSOL)
    printf(">>> CONSOL missing counts: ")
    j = 1
    while (j <= cols(CONSOL)) {
        printf("%f ", Cmiss[j])
        j = j + 1
    }
    printf("\n")
    // =================================================

    /* 璧风偣锛氱敱 Stata 鏈湴瀹?have_b0 鎺у埗 */
    real scalar use_b0
    use_b0 = strtoreal(st_local("have_b0"))  // 浠?st_local 璇诲彇
    printf(">> [Mata] have_b0 = %f\n", use_b0)
        
    // ---- 鍦ㄨ繖閲屽姞涓€灞傜淮搴︿笌缂哄け妫€鏌?----
    printf(">>> DEBUG: rows(X)=%f cols(X)=%f  rows(Y)=%f cols(Y)=%f\n",
        rows(X), cols(X), rows(Y), cols(Y))

    if (rows(X) != rows(Y)) {
        errprintf(">>> ERROR: rows(X) != rows(Y) in qrsolve\n")
        _error(3497)
    }

    if (cols(Y) != 1) {
        errprintf(">>> ERROR: Y is not a column vector in qrsolve\n")
        _error(3497)
    }

    if (any(missing(X))) {
        errprintf(">>> ERROR: X contains missing values before qrsolve\n")
        _error(3497)
    }

    if (any(missing(Y))) {
        errprintf(">>> ERROR: Y contains missing values before qrsolve\n")
        _error(3497)
    }

    if (use_b0 == 1) {
        beta_init = st_matrix("b0")'
        printf(">> Using previous converged beta as starting point\n")
        if (cols(beta_init) != cols(X)) {
            printf(">> WARN: dimensions mismatch (beta_init=%f, X=%f). Recomputing OLS start via qrsolve.\n", cols(beta_init), cols(X))
            beta_init = qrsolve(X, Y)'   // OLS 璧风偣
        }
    }
    else {
        beta_init = qrsolve(X, Y)'       // 鐩存帴鐢?OLS 璧风偣
        printf(">> Using OLS (qrsolve) as starting point\n")
    }

    printf(">>> DEBUG: beta_init loaded, cols(beta_init)=%f\n", cols(beta_init))
}

/*
   === 浼樺寲 2: 閲嶆瀯 GMM_DL_weighted() 鍑芥暟 ===
   鍘熷洜锛氬師浠ｇ爜鍦?d0 妯″紡涓嬩篃璁＄畻姊害锛岃繖鏄啑浣欑殑
   瑙ｅ喅鏂规锛氫粎鍦ㄩ渶瑕佹搴︽椂(todo>=1)璁＄畻姊害
   姝ゅ锛?) 娣诲姞鏇磋缁嗙殑鏃╁仠鏉′欢 2) 浼樺寲鏁板€兼搴﹁绠?*/

void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg, Wg_opt // 鈫?NEW

    real colvector OMEGA, OMEGA_lag, XI, gb, m
    real matrix POOL
	real scalar N, crit_val  // 鈫?NEW

	  // ======= 鍏ㄥ眬鍋ユ锛氬鏋滄牱鏈お灏忔垨 Z 鏈夌己澶憋紝鐩存帴杩斿洖澶х洰鏍囧€?=======
    N = rows(Z)
    if (N <= 5 | any(missing(Z))) {
        // 娌℃湁瓒冲鏍锋湰鎴栧伐鍏峰彉閲忛噷鏈夌己澶憋細缁欎竴涓緢澶х殑鐩爣鍊硷紝姊害璁句负 0
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }
	
	    // 鈽?杩欓噷鍔犱竴灞傞槻鎶わ細濡傛灉 Wg_opt 杩樻病琚?run_two_step 姝ｇ‘璁惧畾锛屽氨鐢ㄥ崟浣嶇煩闃靛厹搴?    if (rows(Wg_opt)==0 | cols(Wg_opt)==0 | rows(Wg_opt)!=cols(Z) | cols(Wg_opt)!=cols(Z)) {
        Wg_opt = I(cols(Z))
    }
	
	
    OMEGA     = PHI     - X     * b'
    OMEGA_lag = PHI_lag - X_lag * b'

    if (cols(CONSOL)>0) POOL = (C, OMEGA_lag, CONSOL)
    else                POOL = (C, OMEGA_lag)

    gb  = qrsolve(POOL, OMEGA)
    XI  = OMEGA - POOL * gb

	N = rows(Z);
    m    = quadcross(Z, XI) :/ N  ;    // 鈫?NEW: 鐢ㄦ牱鏈钩鍧?	
	
    crit_val = m' * Wg_opt * m;
    // ====== 闃叉 missing / 闈炴湁闄?鐨勭洰鏍囧€?======
    if (missing(crit_val) | crit_val>1e+30 | crit_val<-1e+30) {
        // 浠讳綍鏁板€肩偢鎺夛紝涓€寰嬭繑鍥炰竴涓法澶х殑鏈夐檺鍊?        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    // ===== 鏃╁仠锛氬鏋滅洰鏍囧€煎凡缁忛潪甯稿皬锛岀洿鎺ヨ繑鍥?=====
    if (crit_val < 1e-10 * N) {
        crit = crit_val
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    // 姝ｅ父鎯呭喌
    crit = crit_val

    /* 鏁板€兼搴︼細鐩稿姝ラ暱 + 涓績宸垎锛堣鍚戦噺锛?*/
    if (todo>=1) {
        real scalar i, eps_i, fplus, fminus,crit_plus, crit_minus
        real rowvector gnum, btmp
        real colvector Oe, Oel, XI2p, XI2m, m2p, m2m
        real matrix PO

        gnum = J(1, cols(b), .)

        for (i=1; i<=cols(b); i++) {
            // 鍔ㄦ€佹闀匡細鍩虹姝ラ暱 1e-6锛屾牴鎹弬鏁板昂搴﹁皟鏁?            eps_i = scalarmax(1e-6, 1e-6 * abs(b[i]))

            // +eps
            btmp    = b
            btmp[i] = b[i] + eps_i
            Oe  = PHI     - X     * btmp'
            Oel = PHI_lag - X_lag * btmp'
            PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
            gb  = qrsolve(PO, Oe)
            XI2p = Oe - PO*gb;
            m2p  = quadcross(Z, XI2p):/ N
            crit_plus = m2p' * Wg_opt * m2p

            // -eps
            btmp    = b
            btmp[i] = b[i] - eps_i
            Oe  = PHI     - X     * btmp'
            Oel = PHI_lag - X_lag * btmp'
            PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
            gb  = qrsolve(PO, Oe)
            XI2m = Oe - PO*gb;
            m2m  = quadcross(Z, XI2m):/ N
            crit_minus = m2m' * Wg_opt * m2m

          // --- 淇濋櫓涓濓細濡傛灉浠讳竴杈圭殑鐩爣鏄?missing锛屽氨鎶婅繖涓€缁存搴﹁鎴?0 ---
if (missing(crit_plus) | missing(crit_minus)) {
    gnum[i] = 0
}
else {
    // 涓績宸垎姊害
    gnum[i] = (crit_plus - crit_minus) / (2*eps_i)
}
        }

        g = gnum   // 涓?b 鍚屼负琛屽悜閲?    }
}

void run_two_step()
{
    // 鈥斺€?鍒濆鍖栵細灏辩畻澶辫触涔熶繚璇佽繖浜涙爣閲忓瓨鍦?鈥斺€?
    st_numscalar("gmm_conv1", 0)
    st_numscalar("gmm_conv2", 0)
    st_numscalar("gmm_conv",  0)
    st_numscalar("J_unit",    .)
    st_numscalar("J_opt",     .)
    st_numscalar("J_df",      .)
    st_numscalar("J_p",       .)

    // 涓嶅啀鎶?OMEGA2 / XI2 澹版槑涓?external锛岄伩鍏嶅悕瀛楀啿绐?鈥斺€?120娣诲姞 鈥斺€?*
    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg, beta_init, Wg_opt   // 鈥斺€?120娣诲姞 鈥斺€?*

    real scalar Kz, Kx, J1, J2, lam, conv1, conv2, smin, smax, cond, EPSJ
    real rowvector b1, b2
    real colvector OMEGA1, OMEGA1_lag, XI1, OMEGA2_local, OMEGA2_lag, XI2_local, g_bvec, m_unit, m_opt
    real colvector svals
    real matrix POOL1, Mrow, S, POOL2, Wloc
    real scalar N, Junit, Jopt, df, jp
    real scalar conv2_nr, J2_nr
    real rowvector b2_nr
    real scalar Kz_check

    // 鏍锋湰閲?    N = rows(Z)
    st_numscalar("Nobs", N)
    printf("\n>> [GMM] Starting two-step estimation with N=%f observations\n", N)

    // 缁村害妫€鏌?    Kz = cols(Z)
    Kx = cols(X)
    if (Kz < Kx) {
        errprintf("ERROR: Not enough instruments (Kz=%f < Kx=%f). Cannot identify model.\n", Kz, Kx)
        _error(3498)
    }

    // ===== Step 1: Unit weight matrix (I) =====
    Wg_opt = I(Kz)  // I(Kz) 浣滀负绗竴姝ョ殑鍗曚綅鏉冮噸鐭╅樀
    printf(">> Step 1: GMM with unit weight matrix (NM optimization)\n")

    real scalar S1
    S1 = optimize_init()
    optimize_init_evaluator(S1, &GMM_DL_weighted())
    optimize_init_evaluatortype(S1, "d0")     // 涓嶇敤姊害
    optimize_init_which(S1, "min")
    optimize_init_params(S1, beta_init)
    optimize_init_technique(S1, "nm")

    // 鍒濆 simplex 姝ラ暱锛氭瘡涓弬鏁?0.1
    optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.01))

    // 鏀舵暃涓庤凯浠ｈ缃細绗竴姝ュ彧瑕?澶熷ソ"锛屼笉杩芥眰鏋佽嚧绮惧害
    optimize_init_conv_maxiter(S1, 2000)
    optimize_init_conv_ptol(S1, 1e-8)
    optimize_init_conv_vtol(S1, 1e-8)
    optimize_init_tracelevel(S1, "none")

    // 棰勫垎閰?b1
    b1 = J(1, Kx, .)

    // 鈥斺€?鐩存帴浼樺寲 鈥斺€?
    b1    = optimize(S1)
    J1    = optimize_result_value(S1)
    conv1 = optimize_result_converged(S1)

    printf("   Step 1: J1 = %12.6f, converged = %f\n", J1, conv1)
    st_numscalar("gmm_conv1", conv1)

    // 濡傛湭鏀舵暃锛岀缉灏忔闀垮啀璺戜竴娆?    if (!conv1) {
        printf("   Step 1 did not converge. Trying smaller simplex deltas...\n")
        optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.01))
        optimize_init_params(S1, b1)

        b1    = optimize(S1)
        J1    = optimize_result_value(S1)
        conv1 = optimize_result_converged(S1)

        printf("   Step 1 restarted: J1 = %12.6f, converged = %f\n", J1, conv1)
        st_numscalar("gmm_conv1", conv1)
    }

    // ===== Step 1.5: Compute optimal weight matrix =====
    printf(">> Computing optimal weight matrix from Step 1 residuals\n")
    OMEGA1     = PHI     - X     * b1'
    OMEGA1_lag = PHI_lag - X_lag * b1'

    if (cols(CONSOL)>0) POOL1 = (C, OMEGA1_lag, CONSOL)
    else                POOL1 = (C, OMEGA1_lag)

    XI1  = OMEGA1 - POOL1 * qrsolve(POOL1, OMEGA1)
    Mrow = Z :* (XI1 * J(1, cols(Z), 1))

    S    = (Mrow' * Mrow) :/ N   // 鏍囧噯鍖?鈥斺€?120娣诲姞 鈥斺€?*

    // 浣跨敤 SVD 妫€鏌ユ潯浠舵暟锛屾坊鍔犺嚜閫傚簲 ridge
    svals = svdsv(S)
    smin  = min(svals)
    smax  = max(svals)
    cond  = smax / scalarmax(smin, 1e-12)

    lam = 0
    if (cond > 1e6) {
        lam = scalarmax(1e-4, (1e-6 * smax))
        printf("   WARN: S matrix ill-conditioned (cond=%9.2e). Adding ridge lambda=%9.2e\n", cond, lam)
    }
    else {
        printf("   S matrix condition number: %9.2e (good)\n", cond)
    }

    if (lam > 0) {
        Wloc = invsym(S + lam * I(Kz))
    }
    else {
        Wloc = invsym(S)
    }
    Wg_opt = Wloc
    st_matrix("W_opt", Wg_opt)

    // ===== Step 2: GMM with optimal weight matrix =====
    printf(">> Step 2: GMM with optimal weight matrix\n")
    EPSJ = 1e-8 * N

    real scalar S2
    S2 = optimize_init()
    optimize_init_evaluator(S2, &GMM_DL_weighted())
    optimize_init_evaluatortype(S2, "d0")      // 鐢ㄦ暟鍊兼搴︹€斺€?120娣诲姞 鈥斺€?*
    optimize_init_which(S2, "min")
    optimize_init_params(S2, b1)
    optimize_init_technique(S2, "nm")
	optimize_init_nmsimplexdeltas(S2, J(1, cols(b1), 0.00001))
    optimize_init_conv_maxiter(S2, 3000)
    optimize_init_conv_ptol(S2, 1e-8)
    optimize_init_conv_vtol(S2, 1e-8)
    optimize_init_tracelevel(S2, "none")

    b2 = J(1, Kx, .)
    b2    = optimize(S2)
    J2    = optimize_result_value(S2)
    conv2 = optimize_result_converged(S2)

    printf("   Step 2 (BFGS): J2 = %12.6f, converged = %f\n", J2, conv2)

    // 鑻?BFGS 涓嶆敹鏁涳紝鐢?NM
    if (!conv2) {
        printf("   BFGS did not converge. Switching to Nelder鈥揗ead...\n")

        S2 = optimize_init()
        optimize_init_evaluator(S2, &GMM_DL_weighted())
        optimize_init_evaluatortype(S2, "d0")
        optimize_init_which(S2, "min")
        optimize_init_params(S2, b1)
        optimize_init_technique(S2, "nm")
        optimize_init_nmsimplexdeltas(S2, J(1, cols(b1), 0.00001))
        optimize_init_conv_maxiter(S2, 3000)
        optimize_init_conv_ptol(S2, 1e-9)
        optimize_init_conv_vtol(S2, 1e-9)
        optimize_init_tracelevel(S2, "none")

        b2    = optimize(S2)
        J2    = optimize_result_value(S2)
        conv2 = optimize_result_converged(S2)

        printf("   Step 2 (NM):   J2 = %12.6f, converged = %f\n", J2, conv2)
    }

    // 濡傛湭鏀舵暃鎴?J2 浠嶈緝澶э紝鍙€?NR polishing锛堜繚鐣欎綘鐨勯€昏緫锛?    if (( !conv2 | J2 > EPSJ ) & rows(b2)==1 & cols(b2)==Kx) {
        printf("   Trying Newton鈥揜aphson polishing...\n")

        S2 = optimize_init()
        optimize_init_evaluator(S2, &GMM_DL_weighted())
        optimize_init_evaluatortype(S2, "d0")
        optimize_init_which(S2, "min")
        optimize_init_params(S2, b2)
        optimize_init_technique(S2, "nr")
        optimize_init_conv_maxiter(S2, 15)
        optimize_init_conv_ptol(S2, 1e-7)
        optimize_init_conv_vtol(S2, 1e-7)
        optimize_init_tracelevel(S2, "none")

        b2_nr    = optimize(S2)
        J2_nr    = optimize_result_value(S2)
        conv2_nr = optimize_result_converged(S2)

        if (conv2_nr & (J2_nr <= J2)) {
            b2    = b2_nr
            J2    = J2_nr
            conv2 = conv2_nr
            printf("   NR polishing improved solution: J2 = %12.6f, converged = %f\n", J2, conv2)
        }
        else {
            printf("   NR polishing did not improve J. Keeping previous BFGS/NM result.\n")
        }
    }

    st_numscalar("gmm_conv2", conv2)

    // ===== 璁＄畻鏈€缁堢粺璁￠噺 =====
    OMEGA2_local     = PHI     - X     * b2'          // 鈥斺€?120娣诲姞 鈥斺€?*
    OMEGA2_lag       = PHI_lag - X_lag * b2'

    if (cols(CONSOL)>0) {
        POOL2 = (C, OMEGA2_lag, CONSOL)
    }
    else {
        POOL2 = (C, OMEGA2_lag)
    }

    g_bvec   = qrsolve(POOL2, OMEGA2_local)
    XI2_local = OMEGA2_local - POOL2 * g_bvec  // 鈥斺€?120娣诲姞 鈥斺€?*

    // 鏍锋湰骞冲潎鐭?    m_unit = quadcross(Z, XI2_local) :/ N
    m_opt  = quadcross(Z, XI2_local) :/ N   // 鈥斺€?120娣诲姞 鈥斺€?*

    // J-stat
    Junit = N * quadcross(m_unit, m_unit)
    Jopt  = N * quadcross(m_opt, Wg_opt * m_opt)

    df = Kz - Kx
    jp = .
    if (df > 0 & Jopt >= 0) {
        jp = chi2tail(df, Jopt)
    }
    else {
        printf("WARN: invalid (df, Jopt) for chi2tail: df=%f, Jopt=%f. Set J_p=.\n", df, Jopt)
        jp = .
    }

    printf("\n>> GMM Results:\n")
    printf("   J-stat (unit weight): %12.4f\n", Junit)
    printf("   J-stat (opt weight) : %12.4f  (df=%g, p=%6.4f)\n", Jopt, df, jp)
    printf("   Converged (step1): %f, (step2): %f\n", conv1, conv2)

	
    // ===== 鍒嗚В J 鍒版瘡涓?IV 涓?=====
    // 1) 鍦?IV 绌洪棿"鐨勫垎瑙ｏ細J_opt = N * sum_j m_j * (W m)_j
    real colvector v, J_contrib_iv
    v            = Wg_opt * m_opt                // Kz脳1
    J_contrib_iv = N :* (m_opt :* v)             // 姣忎釜 IV 鍦ㄥ師绌洪棿鐨勮础鐚紙鍙鍙礋锛?
    // 2) 鍦?鐧藉寲鍚庢浜ゅ熀"涓婄殑鍒嗚В锛欽_opt = N * sum_j (m_white_j)^2
    real matrix  Wsym, A
    real colvector m_white, J_contrib_white 

    // W = A' * A锛孧ata 閲?chol(W) 杩斿洖涓婁笁瑙?A锛屼娇寰?A' * A = W
    Wsym = 0.5*(Wg_opt + Wg_opt')
    A    = cholesky(Wsym)
                    // Kz脳Kz
    m_white = A * m_opt                         // Kz脳1
    J_contrib_white = N :* (m_white :^ 2)       // 姣忎釜姝ｄ氦鏂瑰悜瀵?J 鐨勮础鐚紙鍏?鈮?锛?
    // 鍥炲啓鍒?Stata锛岃鍚戦噺褰㈠紡渚夸簬鏌ョ湅
    st_matrix("J_contrib_iv",     J_contrib_iv')
    st_matrix("J_contrib_white",  J_contrib_white')
    // 涓轰簡鍏煎浣犱箣鍓嶇殑 Stata 浠ｇ爜锛屾妸 J_contrib_iv 涔熷瓨鎴?J_contrib
    st_matrix("J_contrib",        J_contrib_iv')

	
	
	
	
    // ===== 淇濆瓨缁撴灉鍒?Stata =====
    st_matrix("beta_lin_step1", b1')
    st_matrix("beta_lin",        b2')
    st_matrix("g_b",             g_bvec)

    st_matrix("moments_unit",    m_unit')
    st_matrix("moments_opt",     m_opt')
    st_matrix("W_opt",           Wg_opt)

    st_numscalar("J_unit",   Junit)
    st_numscalar("J_opt",    Jopt)
    st_numscalar("J_df",     df)
    st_numscalar("J_p",      jp)
    st_numscalar("gmm_conv", (conv1 & conv2))

    // ============ 瀹夊叏鍥炲啓娈嬪樊锛氬姞缁村害妫€鏌?============ 
    real scalar nobs
    nobs = st_nobs()

    if (rows(OMEGA2_local) == nobs) {
        st_store(., "OMEGA2", OMEGA2_local)
    }
    else {
        printf("WARN: OMEGA2 length (%f) != Nobs (%f). Skipping OMEGA2 st_store.\n",
               rows(OMEGA2_local), nobs)
    }

    if (rows(XI2_local) == nobs) {
        st_store(., "XI2", XI2_local)
    }
    else {
        printf("WARN: XI2 length (%f) != Nobs (%f). Skipping XI2 st_store.\n",
               rows(XI2_local), nobs)
    }
    // ===============================================

}

end

program define gmm2step_once, rclass
    version 18
    syntax [, rep(integer 0)]
    
    * 璁板綍寮€濮嬫椂闂?    timer clear 1
    timer on 1
    
 * ===== 鍏堣窇 refresh_globals()锛屽苟妫€鏌?rc =====
	 mata: mata set matastrict on  // 寤鸿寮€ strict 妯″紡锛屾姤閿欐洿娓呮櫚
     mata: refresh_globals()
/*local rc_mata = _rc
if `rc_mata' {
    di as err "ERROR in refresh_globals(): rc=`rc_mata'"
    exit `rc_mata'
}*/

  
 * ===== 鍐嶈窇 run_two_step()锛屽苟妫€鏌?rc =====
 mata: run_two_step()
 local rc_mata = _rc           // <<< 鍏抽敭锛氭崟鑾?run_two_step 鐨勮繑鍥炵爜
 
* 濡傛灉鍙槸 111锛坰implex 璀﹀憡锛夛紝鑰屼笖宸茬粡鏈?J_opt锛屽氨褰撴垚 warning 缁х画
if `rc_mata' == 111 {
    capture confirm scalar J_opt
    if _rc == 0 {
        di as txt "NOTE: run_two_step() returned rc=111 (simplex warning), but J_opt is available. Proceeding."
        local rc_mata = 0
    }
}
* 鍏朵粬 rc 涓€寰嬭涓洪敊璇?if `rc_mata' {
    di as err "ERROR in run_two_step(): rc=`rc_mata'"
    exit `rc_mata'
}
    
* ===== 妫€鏌ユ敹鏁涙爣蹇?=====
confirm scalar gmm_conv
    if _rc {
        di as err "gmm_conv not returned"
        exit 498
    }
    
    if scalar(gmm_conv) != 1 {
        di as txt "WARNING: GMM did not fully converge (gmm_conv=`=scalar(gmm_conv)')"
    }
    
* ===== 鎻愬彇 尾 绯绘暟 =====
 confirm matrix beta_lin
    if _rc {
        di as err "beta_lin not returned"
        exit 498
    }
    
    matrix b = beta_lin
    return scalar b_c1   = b[1,1]
    return scalar b_l    = b[2,1]
    return scalar b_k    = b[3,1]
    return scalar b_lsq  = b[4,1]
    return scalar b_ksq  = b[5,1]
    return scalar b_m    = b[6,1]
    return scalar b_es   = b[7,1]
    return scalar b_essq = b[8,1]
    
    * 鎻愬彇鎺у埗鍙橀噺绯绘暟
 confirm matrix g_b
    if _rc {
        di as err "g_b not returned"
        exit 498
    }
    
    matrix gb = g_b
    * 鎸?CONSOL 椤哄簭锛歡b[9] = lnage, gb[10] = firmcat_2, gb[11] = firmcat_3
    return scalar b_lnage    = gb[9,1]
    return scalar b_firmcat_2 = gb[10,1]
    return scalar b_firmcat_3 = gb[11,1]
    
    * J-statistics
	return scalar J_unit     = scalar(J_unit)
 confirm scalar J_opt
    if !_rc return scalar J_opt = scalar(J_opt)
    
 confirm scalar J_p
    if !_rc return scalar J_p = scalar(J_p)
    
    * 璁℃椂
    timer off 1
    timer list 1
    return scalar time = r(t1)
    
    di as txt "Rep `rep': completed in `=r(t1)' sec. J_opt=`=scalar(J_opt)'"
end

* 鈥斺€?鍏ㄦ牱鏈厛璺戜竴娆★紝鍙栬捣鐐?b0锛屽苟淇濆瓨鐐逛及 鈥斺€?*
local have_b0 0  // 鍒濆鏃犺捣鐐?mata: st_local("have_b0","`have_b0'")
di as text _n(2) "{hline 80}"
di as text "Running full-sample GMM to get starting values and point estimates"
di as text "{hline 80}"

quietly gmm2step_once
local rc = _rc

* r(430) 鍏滃簳锛氳嫢 Mata 宸茬粡鍐欏洖浜嗗緢灏忕殑 J_opt锛屽綋浣滄敹鏁?if (`rc'==430) {
     confirm scalar J_opt
    if (_rc==0 & scalar(J_opt) < 1e-8) {
        di as txt "Flat region; treat as converged because J_opt is tiny."
        scalar gmm_conv = 1
        local rc 0
    }
}

if (`rc'==0) {
     confirm scalar gmm_conv
    if (_rc==0 & scalar(gmm_conv)==1) {
        matrix b0 = beta_lin
        local have_b0 1 // 鏍囪宸茶幏寰楄捣鐐?		mata: st_local("have_b0","`have_b0'")
        di as text "Full-sample GMM converged. Using as starting point for bootstrap."
    }
    else {
        di as err "Full-sample GMM ran but did not converge; cannot save point estimates."
        exit 459
    }
}
else {
    di as err "Full-sample GMM failed (rc=`rc'): cannot save point estimates."
    exit 459
}

* =============== 绾挎€?IV 璇婃柇锛堝彧鍦?full-sample 鏀舵暃鍚庤窇涓€娆★級 ===============
if "`GROUPNAME'" == "G1_17_19" {

    di as text _n(1) "---------- Linear IV diagnostics for G1_17_19 (ivreg2) ----------"

    * 瀹氫箟鍐呯敓鍙橀噺涓?鎺掗櫎鍨嬪伐鍏峰彉閲?
local endog4   l k m es
local z_excl4  l llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_post

    * 娉ㄦ剰锛歝onst銆佸勾浠借櫄鎷熴€乴nage銆乫irmcat_* 浣滀负澶栫敓鍥炲綊閲忥紝
    *       鏃㈣繘鍏ョ粨鏋勫紡锛屼篃鑷姩鎴愪负 IV锛坕vreg2 浼氭妸鎵€鏈夊鐢熷彉閲忓綋浣滃伐鍏凤級銆?ivreg2 r const dy2002-dy2007 lnage firmcat_2 firmcat_3 ///
       (`endog4' = `z_excl4') lsq ksq es2q, ///
       nocons robust cluster(firmid) first

    * 璇存槑锛?    * - r 鏄瑙ｉ噴鍙橀噺锛堝搴斾綘鍦?GMM 涓敤 Y/phi 鐨勯偅涓€閮ㄥ垎锛?    * - const + 骞村害铏氭嫙 + lnage + firmcat_* 鏄鐢熸帶鍒?    * - 鎷彿閲岀殑 l, k, ... 鏄唴鐢熷彉閲忥紝鐢?`z_excl' 杩欑粍 IV 鏉ュ伐鍏峰寲
    * - first 閫夐」浼氱粰鍑烘瘡涓唴鐢熷彉閲忕殑 first-stage F 鍜屽亸鐩稿叧 R^2
    *   浠ュ強鏁翠綋 Kleibergen-Paap rk Wald F锛坵eak IV 璇婃柇锛?}

if "`GROUPNAME'" == "G1_39_41" {

    di as text _n(1) "---------- Linear IV diagnostics for G1_39_41 (ivreg2) ----------"
    capture ssc install ranktest, replace
    capture ssc install ivreg2,   replace
    local endog4   l k m es
    local z_excl4  llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_pos
    ivreg2 r const dy2002-dy2007 lnage firmcat_2 firmcat_3 ///
       (`endog4' = `z_excl4') lsq ksq es2q, ///
       nocons robust cluster(firmid) first
}
* ====================== 绾挎€?IV 璇婃柇缁撴潫 ============================

// full-sample 鎴愬姛鍚庯紝绔嬪埢鎶撳彇涓や釜鎺у埗椤圭郴鏁?local b_lnage_hat     = r(b_lnage)
local b_firmcat2_hat  = r(b_firmcat_2)
local b_firmcat3_hat  = r(b_firmcat_3)

* === 鍏ㄦ牱鏈畫宸凡缁忓湪 run_two_step() 涓啓鍏?OMEGA2 / XI2锛岃繖閲岀洿鎺ョ敤鍗冲彲 鈥斺€?120娣诲姞 鈥斺€?*

* === 杈撳嚭 firm-level omega_hat / xi_hat锛堝叏鏍锋湰锛?===
capture drop omega_hat xi_hat   // 涓嶅瓨鍦ㄥ氨闈欓粯璺宠繃锛屼笉鎶ラ敊
gen double omega_hat = OMEGA2
gen double xi_hat    = XI2

*锛堝彲閫夛級鍩烘湰鍋ユ锛氫笉搴旀湁缂哄け
qui count if missing(omega_hat, xi_hat)
if r(N) > 0 {
    di as txt "WARNING: `r(N)' missing values in omega_hat/xi_hat"
}

* 鍙暀鍏抽敭闈㈡澘閿笌缁撴灉锛屾寜缁勫悕杈撳嚭涓€涓枃浠?preserve
    keep firmid year cic2 omega_hat xi_hat
    gen str10 group = "`GROUPNAME'"
    order group firmid year cic2 omega_hat xi_hat
    compress
    save "$DATA_WORK/omega_xi_group_`GROUPNAME'.dta", replace
restore

* 鈥斺€?鐜板湪淇濆瓨鍏ㄦ牱鏈偣浼?鈥斺€?*
quietly count
local Nobs = r(N)
preserve
    clear
    set obs 1
    gen group = "`GROUPNAME'"
    matrix b = beta_lin
    gen b_const = b[1,1]
    gen b_l     = b[2,1]
    gen b_k     = b[3,1]
    gen b_lsq   = b[4,1]
    gen b_ksq   = b[5,1]
    gen b_m     = b[6,1]
    gen b_es    = b[7,1]
    gen b_essq  = b[8,1]
	    // 鍙啓 lnage 涓?firmtype 涓や釜鎺у埗椤圭殑绯绘暟锛堜竴娆″洖褰掔偣浼帮級=====
    gen b_lnage     = `b_lnage_hat'
    gen b_firmcat_2 = `b_firmcat2_hat'
    gen b_firmcat_3 = `b_firmcat3_hat'
	
    gen J_unit  = J_unit
    gen J_opt   = J_opt
    gen J_df    = J_df
    gen J_p     = J_p
    gen N       = `Nobs'
    order group b_const b_l b_k b_lsq b_ksq b_m b_es b_essq ///
          b_lnage b_firmcat_2 b_firmcat_3 ///
          J_unit J_opt J_df J_p N
    compress
    save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace
restore

* ===== 鍦ㄥ叏鏍锋湰浼拌鍚庣珛鍗冲睍绀烘牳蹇冪粨鏋滐紝鏂逛究妫€鏌?Step1 / Step2 / J =====  * 鈥斺€?120娣诲姞 鈥斺€?*
matrix list beta_lin_step1
matrix list beta_lin
matrix list moments_unit
matrix list moments_opt
scalar list J_unit J_opt J_df J_p gmm_conv
display as text "J_opt = " J_opt "  (df = " J_df ", p = " J_p ")"

// 鐪嬩竴涓嬩笁绫?J 鍒嗚В鐭╅樀
matrix list J_contrib           // = J_contrib_iv锛堝吋瀹圭敤锛?matrix list J_contrib_iv
matrix list J_contrib_white

// ---- 鎶婃瘡涓?IV 鐨?m_opt 鍜?J_contrib 鎵撳嵃鍑烘潵 ----

// 1) 鏍规嵁 moments_opt 鐨勫垪鏁拌嚜鍔ㄨ瘑鍒?Kz锛岄伩鍏嶆墜鍔ㄥ啓 9/10 鎼為敊
local Kz = colsof(moments_opt)

// 2) Z 鐨勫悕瀛楋細杩欓噷涓€瀹氳鍜屽疄闄?IV 鏁伴噺 Kz 瀵归綈锛堟瘮濡?9 涓級
local Znames const l llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_post

forvalues j = 1/`Kz' {
    local zname : word `j' of `Znames'
    
    // 浠庣煩闃典腑鍙栧嚭褰撳墠 IV 鐨勭煩鍊煎拰涓ょ J 璐＄尞
    scalar m_j      = moments_opt[1, `j']
    scalar J_iv_j   = J_contrib_iv[1, `j']
    scalar Jw_j     = J_contrib_white[1, `j']
    
    // 閬垮厤闄ら浂锛屽厛榛樿 share 涓?.
    scalar share_iv = .
    if (J_opt != 0) scalar share_iv = J_iv_j / J_opt
    
    di as txt "`zname':  m_opt = " %9.5f m_j ///
        "   J_iv = " %9.5f J_iv_j ///
        "   share_iv = " %6.3f share_iv ///
        "   J_white = " %9.5f Jw_j
}

* 鈥斺€?Bootstrap 寰幆 鈥斺€?*
di as text _n(2) "{hline 80}"
di as text "Starting bootstrap estimation (clustered by firmid)"
di as text "{hline 80}"

tempname H
tempfile bootres
local failed = 0
local total_time = 0

* === 浼樺寲 11: 鍥哄畾 seed 澧炲己鍙鐜版€?===
set seed 20250830
local B = 2  // 璋冭瘯鐢紝姝ｅ紡杩愯璇疯涓?200+

* === 浼樺寲 4: 璁板綍澶辫触鍘熷洜 ===
tempfile failures
postfile failures rep reason using "`failures'", replace

postfile `H' rep double(b_const b_l b_k b_lsq b_ksq b_m b_es b_essq b_lnage b_firmcat_2 b_firmcat_3 J_unit J_opt time) ///
    using "`bootres'", replace

forvalues ro = 1/`B' {
    di as text _n "Bootstrap rep `ro'/`B'"
    
    preserve
        * === 淇 9: 姝ｇ‘閲嶅缓闈㈡澘缁撴瀯 ===
        quietly bsample, cluster(firmid) idcluster(newfid)
        
        * 鐢ㄦ柊ID閲嶅缓闈㈡澘
        gen long orig_firmid = firmid
        replace firmid = newfid
        xtset firmid year
        
        * 纭繚T>=2
        by firmid: gen byte __T = _N
        keep if __T >= 2
        drop __T
        
        qui count
        local N_bs = r(N)
        di as text "  Sample size after keeping T>=2: `N_bs'"
        
        if (`N_bs' < 50) {
            di as txt "  WARNING: Very small sample (`N_bs' obs). May not converge."
        }
        

        
        * 浼拌
         noisily gmm2step_once, rep(`ro')
        local rc = _rc
        
        if (`rc' == 0) {
            * 妫€鏌ユ敹鏁?             confirm scalar gmm_conv
            if _rc {
                local reason "gmm_conv not returned"
                local rc 499
            }
            else if scalar(gmm_conv) != 1 {
                local reason "not converged (gmm_conv=`=scalar(gmm_conv)')"
                local rc 499
            }
        }
        else {
            local reason "gmm2step_once failed with rc=`rc'"
        }
        
        * 浠呭湪鎴愬姛涓旀敹鏁涙椂璁板綍
        if (`rc' == 0 & scalar(gmm_conv) == 1) {
            post `H' (`ro') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_lsq)) (r(b_ksq)) (r(b_m)) ///
                   (r(b_es)) (r(b_essq)) (r(b_lnage)) (r(b_firmcat_2)) (r(b_firmcat_3)) ///
               (r(J_unit)) (r(J_opt)) (r(time))
            
            * 鏇存柊璧风偣
             confirm matrix beta_lin
            if (_rc == 0) {
                matrix b0 = beta_lin
                local have_b0 1
            }
            else {
                di as txt "  WARNING: beta_lin not available, cannot update starting point"
            }
            
            local total_time = `total_time' + r(time)
            di as result "  SUCCESS: rep `ro' converged in `=r(time)' sec"
        }
        else {
            local ++failed
            post failures (`ro') ("`reason'")
            di as error "  FAILED: rep `ro' - `reason'"
        }
    restore
}

postclose `H'
postclose failures

di as result _n(2) "Bootstrap completed:"
di as result "  Total reps: `B'"
di as result "  Successful: `=`B'-`failed''"
di as result "  Failed: `failed'"
if (`B' > `failed') {
    di as result "  Avg time per rep: `=`total_time'/(`B'-`failed')' sec"
}
else {
    di as err "  All reps failed; avg time not defined."
}

* 淇濆瓨澶辫触璁板綍
use "`failures'", clear
if _N > 0 {
    list, noobs
    save "$DATA_WORK/bootstrap_failures_`GROUPNAME'.dta", replace
}

* 璇诲彇 bootstrap 缁撴灉
use "`bootres'", clear
if _N == 0 {
    di as err "No successful bootstrap replications. Cannot compute SEs."
    exit 430
}

* 鈥斺€?璁＄畻鏍囧噯璇?鈥斺€?*
qui summarize b_const, detail
local se_const = r(sd)
qui summarize b_l, detail
local se_l     = r(sd)
qui summarize b_k, detail
local se_k     = r(sd)
qui summarize b_lsq, detail
local se_lsq   = r(sd)
qui summarize b_ksq, detail
local se_ksq   = r(sd)
qui summarize b_m, detail
local se_m     = r(sd)
qui summarize b_es, detail
local se_es    = r(sd)
qui summarize b_essq, detail
local se_essq  = r(sd)
qui summarize b_lnage, detail
local se_lnage     = r(sd)
qui summarize b_firmcat_2, detail
local se_firmcat_2 = r(sd)
qui summarize b_firmcat_3, detail
local se_firmcat_3 = r(sd)
qui summarize J_unit, detail
local se_J_unit = r(sd)

qui summarize J_opt, detail
local se_J_opt = r(sd)

* 鈥斺€?闄勫姞鍒扮偣浼拌鏂囦欢 鈥斺€?*
use "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", clear
gen se_const = `se_const'
gen se_l     = `se_l'
gen se_k     = `se_k'
gen se_lsq   = `se_lsq'
gen se_ksq   = `se_ksq'
gen se_m     = `se_m'
gen se_es    = `se_es'
gen se_essq  = `se_essq'
gen se_lnage     = `se_lnage'
gen se_firmcat_2 = `se_firmcat_2'
gen se_firmcat_3 = `se_firmcat_3'
gen se_J_unit = `se_J_unit'
gen se_J_opt  = `se_J_opt'
gen boot_reps = `=`B'-`failed''
gen avg_time = `=`total_time'/(`B'-`failed')'

replace J_df = scalar(J_df)
replace J_p = scalar(J_p)
order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq b_m se_m b_es se_es b_essq se_essq ///
      b_lnage se_lnage b_firmcat_2 se_firmcat_2 b_firmcat_3 se_firmcat_3 ///
      J_unit se_J_unit J_opt se_J_opt J_df J_p N boot_reps avg_time

compress
save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace

* 鈥斺€?淇濆瓨 bootstrap draws 鈥斺€?*
use "`bootres'", clear
compress
save "$DATA_WORK/gmm_boot_group_`GROUPNAME'.dta", replace

di as res _n(2) "{hline 80}"
di as res "Done group `GROUPNAME'. Files written:"
di as res "  gmm_point_group_`GROUPNAME'.dta   (points + bootstrap SEs + diagnostics)"
di as res "  gmm_boot_group_`GROUPNAME'.dta    (draws)"
di as res "  omega_xi_group_`GROUPNAME'.dta   (firm-level residuals)"
if `failed' > 0 di as res "  bootstrap_failures_`GROUPNAME'.dta (failure reasons)"
di as res "{hline 80}"

* === 鏂板锛氳褰曠粨鏉熸椂闂?===
local end_time = c(current_time)
display as text "INFO: Script finished at `end_time'"
