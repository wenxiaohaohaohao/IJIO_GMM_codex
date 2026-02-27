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
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/cobb_douglas"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"
cd "$ROOT"
* 姣忎釜缁勫紑澶撮兘閲嶇疆璧风偣锛屽苟鎶?have_b0 浼犲叆 Mata
local have_b0 0                      

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
/*
merge 1:m firmid year using "$DATA_RAW/nonneutraltartiff.dta"
keep if _merge==3
drop _merge
*/


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
capture confirm numeric variable year
if _rc destring year, replace ignore(" -/,")
xtset firmid year

// ===== Your pipeline (unchanged aside from tariff inclusion) =====
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

capture confirm variable firmtotalq
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
*drop if ratio<0.02    *************************************change
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
xtset firmid year

capture confirm variable pft
if !_rc rename pft pi
capture confirm variable foreignprice
if !_rc rename foreignprice WX
capture confirm variable WX
if !_rc gen double wx = ln(WX)

* First stage  (ADD tariff as you asked)(鍏堟妸鍏崇◣鍒犻櫎鎺夛紝涔嬪悗鍐嶈)
reg lratiofs k l wl x age lnmana i.firmtype i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2

* phi cubic (unchanged)
reg r c.(l k m x pi wx wl )##c.(l k m x pi wx wl )##c.(l k m x pi wx wl) ///
    age i.firmtype i.city i.year
// 鍥炲綊锛堜綘鐨勭涓€闃舵锛夊悗锛氶娴嬪悗鍙鏈夋晥鏍锋湰璧嬪€硷紙閬垮厤 predict 鍥犵己椤逛骇鐢熺殑 173 涓己澶辨贩鍏ワ級
predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "$DATA_WORK/firststage.dta", replace

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
 


gen double kl = k*l
gen byte   const = 1

capture confirm variable const
if _rc gen byte const = 1
order firmid year, first
drop if missing(r,l,k,m,x,phi,phi_lag,llag,mlag,xlag,klag,lnage,firmtype)

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
isid firmid year
xtset firmid year

*==================== Mata (two-step GMM; add tariff to CONSOL) ====================*
mata:
mata clear
Wg     = J(0,0,.)
OMEGA2 = J(0,1,.)
XI2    = J(0,1,.)

void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init

  
    X       = st_data(., ("const","l","k","m","x"))
    X_lag   = st_data(., ("const","llag","klag","mlag","xlag"))
/* IV sets by group name (no anchor needed) */
string scalar g
 g = st_global("GROUP_NAME")
     printf(">> [Mata] GROUPNAME seen: [%s]\n", g)
if (g!="G1_17_19" & g!="G2_39_41") {
        errprintf("Invalid GROUPNAME = [%s]; must be G1_17_19 or G2_39_41\n", g)
        _error(3499)
    }

if (g=="G1_17_19") {
    // 鍘熷厛 anchor=18 鐨?IV锛圞z=9锛?    Z = st_data(., ("const","k","mlag","xlag","mlagk","llag"))
	printf(">> Using IV: IV_anchor18_Kz9\n")
}
else  {
    // 鍘熷厛 anchor=40 鐨?IV锛圞z=9锛?    Z = st_data(., ("const","k","xlag","llag","xllagl", "mlag"))
	printf(">> Using IV: IV_anchor40_Kz9\n")
}

    PHI     = st_data(., "phi")
    PHI_lag = st_data(., "phi_lag")
    Y       = st_data(., "r")
    C       = st_data(., "const")

    // Controls锛堝悗缁瑕佸姞鍏崇◣鍐嶆斁杩涜繖閲岋級
    CONSOL  = st_data(., ("dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","lnage","firmtype"))

    /* 璧风偣锛氱敱 Stata 鏈湴瀹?have_b0 鎺у埗 */
    real scalar use_b0
    use_b0 = strtoreal(st_local("have_b0"))
    if (use_b0==1) {
        beta_init = st_matrix("b0")'
        if (cols(beta_init)!=cols(X)) beta_init = (invsym(X'X) * (X'Y))'
    }
    else {
        beta_init = (invsym(X'X) * (X'Y))'
    }
}

void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg

    real colvector OMEGA, OMEGA_lag, XI, gb, m
    real matrix POOL

    OMEGA     = PHI     - X     * b'
    OMEGA_lag = PHI_lag - X_lag * b'

    if (cols(CONSOL)>0) POOL = (C, OMEGA_lag, CONSOL)
    else                POOL = (C, OMEGA_lag)

    gb  = qrsolve(POOL, OMEGA)
    XI  = OMEGA - POOL * gb

    real scalar N;
	N = rows(Z);
    m    = quadcross(Z, XI) :/ N  ;    // 鈫?NEW: 鐢ㄦ牱鏈钩鍧?    crit = m' * Wg * m;
  // --- 鏃╁仠锛氱洰鏍囧€兼瀬灏忓氨鐩存帴鍛婅瘔浼樺寲鍣?姊害=0"锛岄伩鍏嶇户缁?line-search ---
    if (crit < 1e-8) {              // 闃堝€煎彲 1e-14 ~ 1e-18 涔嬮棿閫?        if (todo>=1) g = J(1, cols(b), 0)
        return
    }

    /* 鏁板€兼搴︼細鐩稿姝ラ暱 + 涓績宸垎锛堣鍚戦噺锛?*/
    if (todo>=1) {
        real scalar i, eps_i, fplus, fminus
        real rowvector gnum, btmp
        real colvector Oe, Oel, XI2p, XI2m, m2p, m2m
        real matrix PO

        gnum = J(1, cols(b), .)

        for (i=1; i<=cols(b); i++) {
            eps_i = 5e-6 * (1 + abs(b[i]))

            // +eps
            btmp    = b
            btmp[i] = b[i] + eps_i
            Oe  = PHI     - X     * btmp'
            Oel = PHI_lag - X_lag * btmp'
            PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
            gb  = qrsolve(PO, Oe)
            XI2p = Oe - PO*gb;
            m2p  = quadcross(Z, XI2p):/ N
            fplus = m2p' * Wg * m2p

            // -eps
            btmp    = b
            btmp[i] = b[i] - eps_i
            Oe  = PHI     - X     * btmp'
            Oel = PHI_lag - X_lag * btmp'
            PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
            gb  = qrsolve(PO, Oe)
            XI2m = Oe - PO*gb;
            m2m  = quadcross(Z, XI2m):/ N
            fminus = m2m' * Wg * m2m

            gnum[i] = (fplus - fminus) / (2*eps_i)
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

    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg, OMEGA2, XI2, beta_init

    real scalar Kz, Kx, S1, S2, J1, J2, lam, conv1, conv2, smin, delta1, delta2
    real rowvector b1, b2
    real colvector OMEGA1, OMEGA1_lag, XI1, OMEGA2_local, OMEGA2_lag, XI2_local, g_bvec, m2, sv
    real matrix POOL1, Mrow, S, POOL2

    /* step 1: unit W  鈥斺€? NM */
    Kz = cols(Z)
    Kx = cols(X)
    Wg = I(Kz)

    S1 = optimize_init()
    optimize_init_evaluator(S1, &GMM_DL_weighted())
    optimize_init_evaluatortype(S1, "d0")
    optimize_init_which(S1, "min")
    optimize_init_params(S1, beta_init)
    optimize_init_technique(S1, "nm")
	optimize_init_nmsimplexdeltas(S1, 0.08)
    optimize_init_conv_maxiter(S1, 800)
    optimize_init_conv_ptol(S1, 1e-6)
    optimize_init_conv_vtol(S1, 1e-7)
    optimize_init_tracelevel(S1, "value")

    b1    = optimize(S1)
    J1    = optimize_result_value(S1)
    conv1 = optimize_result_converged(S1)
/*
    if (!conv1) {
        delta1 = 0.05
        S1 = optimize_init()
        optimize_init_evaluator(S1, &GMM_DL_weighted())
        optimize_init_evaluatortype(S1, "d1")
        optimize_init_which(S1, "min")
        optimize_init_params(S1, b1)
        optimize_init_technique(S1, "nm")
        optimize_init_nmsimplexdeltas(S1, delta1)
        optimize_init_conv_maxiter(S1, 600)
        optimize_init_tracelevel(S1, "value")

        b1    = optimize(S1)
        J1    = optimize_result_value(S1)
        conv1 = optimize_result_converged(S1)
    }
*/
    /* optimal W from step-1 residuals + ridge */
    OMEGA1     = PHI - X*b1'
    OMEGA1_lag = PHI_lag - X_lag*b1'
    if (cols(CONSOL)>0) POOL1 = (C, OMEGA1_lag, CONSOL)
    else                POOL1 = (C, OMEGA1_lag)

    XI1  = OMEGA1 - POOL1 * qrsolve(POOL1, OMEGA1)
    Mrow = Z :* (XI1 * J(1, cols(Z), 1))

    S    = (Mrow' * Mrow) :/ rows(Z)  // 鈫?NEW: 涔熸寜 N 鏍囧噯鍖?
    sv   = svdsv(S)
    smin = min(sv)
    if (smin < 1e-6) lam = 1e-6 - smin; else lam = 0

    Wg = invsym(S + lam * I(Kz))
    if (rows(Wg)==0) Wg = pinv(S + lam * I(Kz))

/* step 2: optimal W 鈥斺€?鐩存帴鐢?NM(d0) 涓讳紭鍖栵紝鏈€鍚庡啀鐢?NR 灏忔鏁版姏鍏?*/
real scalar EPSJ
EPSJ = 1e-6 * rows(Z)    // 缁熶竴鐨?寰堝皬"闂ㄦ锛屼綘涔熷彲浠ョ敤 1e-10 鏇村鏉?
// --- NM 涓讳紭鍖栵紙鏃犳搴︼級 ---
S2 = optimize_init()
optimize_init_evaluator(S2, &GMM_DL_weighted())
optimize_init_evaluatortype(S2, "d0")        // 鈫?鍏抽敭锛歂M 鐢?d0
optimize_init_which(S2, "min")
optimize_init_params(S2, b1)
optimize_init_technique(S2, "nm")
optimize_init_nmsimplexdeltas(S2, 0.03)      // 鍒濆鍗曠函褰㈡闀匡紝鎸夐渶 0.01~0.1 璋?optimize_init_conv_maxiter(S2, 200)
optimize_init_conv_ptol(S2, 1e-6)
optimize_init_conv_vtol(S2, 1e-6)
// 灏忔牱鏈?鑷妇寰幆閲屽缓璁畨闈欙細鎶?"value" 鏀规垚 "none"
optimize_init_tracelevel(S2, "none")

b2    = optimize(S2)
J2    = optimize_result_value(S2)
conv2 = optimize_result_converged(S2)

// --- 濡傛灉鐩爣宸茬粡鏋佸皬锛岀洿鎺ヨ涓哄凡鏀舵暃锛岃烦杩?NR ---
if (J2 <= EPSJ) {
    conv2 = 1
}

// --- 缁熶竴闂ㄦ锛氬彧瑕?J2 杩樺ぇ锛屽氨鎶涘厜锛堜笉鐪?conv2锛?--
if (J2 > EPSJ) {
    // 鍏?BFGS锛堢ǔ锛?    S2 = optimize_init()
    optimize_init_evaluator(S2, &GMM_DL_weighted())
    optimize_init_evaluatortype(S2, "d1")
    optimize_init_which(S2, "min")
    optimize_init_params(S2, b2)
    optimize_init_technique(S2, "bfgs")
    optimize_init_conv_maxiter(S2, 60)
    optimize_init_conv_ptol(S2, 1e-6)
    optimize_init_conv_vtol(S2, 1e-6)
    optimize_init_tracelevel(S2, "none")

    b2    = optimize(S2)
    J2    = optimize_result_value(S2)

    // 杩樹笉澶燂紝鍐?NR 灏戦噺姝ュ厹搴?    if (J2 > EPSJ) {
        S2 = optimize_init()
        optimize_init_evaluator(S2, &GMM_DL_weighted())
        optimize_init_evaluatortype(S2, "d1")
        optimize_init_which(S2, "min")
        optimize_init_params(S2, b2)
        optimize_init_technique(S2, "nr")
        optimize_init_conv_maxiter(S2, 10)
        optimize_init_conv_ptol(S2, 1e-7)
        optimize_init_conv_vtol(S2, 1e-7)
        optimize_init_tracelevel(S2, "none")

        b2    = optimize(S2)
        J2    = optimize_result_value(S2)
    }
}


    /* back out xi, moments */
    OMEGA2_local = PHI - X*b2'
    OMEGA2_lag   = PHI_lag - X_lag*b2'
    if (cols(CONSOL)>0) POOL2 = (C, OMEGA2_lag, CONSOL)
    else                POOL2 = (C, OMEGA2_lag)

    g_bvec    = qrsolve(POOL2, OMEGA2_local)
    XI2_local = OMEGA2_local - POOL2 * g_bvec

    // ----- 缁村害鍋ユ -----
    if (rows(Z)!=rows(X) | rows(Z)!=rows(PHI)) {
        errprintf("run_two_step(): row mismatch: rows(Z)=%f, rows(X)=%f, rows(PHI)=%f\n", rows(Z), rows(X), rows(PHI))
        _error(3200)
    }
    if (cols(Wg)!=cols(Z) | rows(Wg)!=cols(Z)) {
        // 鑻ユ潈閲嶇煩闃垫病琚纭濂斤紝灏遍€€鍥炲崟浣嶆潈閲嶏紝涓嶈缁村害鐐?        Wg = I(cols(Z))
    }

    // 鏍锋湰骞冲潎鐭?    real colvector m_unit
    m_unit = quadcross(Z, OMEGA1 - ( (cols(CONSOL)>0 ? (C, OMEGA1_lag, CONSOL) : (C, OMEGA1_lag)) * qrsolve( (cols(CONSOL)>0 ? (C, OMEGA1_lag, CONSOL) : (C, OMEGA1_lag)), OMEGA1 ) )) :/ rows(Z)
    m2     = quadcross(Z, XI2_local) :/ rows(Z)

    // ----- 淇濆瓨涓棿缁撴灉锛堝拰浣犲師鏉ヤ竴鑷达級 -----
    st_matrix("beta_lin_step1", b1')
    st_matrix("beta_lin",        b2')
    st_matrix("g_b",             g_bvec)
    st_matrix("moments_unit",    m_unit)
    st_matrix("moments_opt",     m2)
    st_matrix("W_opt",           Wg)
    st_numscalar("gmm_conv1",    conv1)
    st_numscalar("gmm_conv2",    conv2)

// ===== 鍏堢畻 J 瑕佺礌锛屽啀鍒ゅ畾鏀舵暃 =====
real scalar Junit, Jopt, df, jp

Junit = rows(Z) * sum(m_unit :* m_unit)
Jopt  = rows(Z) * sum(m2 :* (Wg * m2))


df = cols(Z) - cols(X)
jp = .
if (df>0) jp = chi2tail(df, Jopt)

st_numscalar("J_unit", Junit)
st_numscalar("J_opt",  Jopt)
st_numscalar("J_df",   df)
st_numscalar("J_p",    jp)

st_numscalar("gmm_conv", (st_numscalar("gmm_conv1") & st_numscalar("gmm_conv2")))


    // 鍥炲啓缁欏叏灞€锛堜緵澶栭潰鍙栫敤锛?    OMEGA2 = OMEGA2_local
    XI2    = XI2_local

}
end



* ---------- Bootstrap (cluster by firmid) ----------
program define gmm2step_once, rclass
    version 18

     mata: refresh_globals()
     mata: run_two_step()
    matrix b = beta_lin
    return scalar b_c1   = b[1,1]
    return scalar b_l    = b[2,1]
    return scalar b_k    = b[3,1]
    return scalar b_m    = b[4,1]
    return scalar b_x   = b[5,1]
end



* 鍒濆娌℃湁 b0
* 鈥斺€?鍏ㄦ牱鏈厛璺戜竴娆★紝鍙栬捣鐐?b0锛屽苟淇濆瓨鐐逛及 鈥斺€?*
local have_b0 0
mata: st_local("have_b0","`have_b0'")
*mata: st_local("GROUPNAME","`GROUPNAME'")          
capture noisily gmm2step_once
local rc = _rc

* r(430) 鍏滃簳锛氳嫢 Mata 宸茬粡鍐欏洖浜嗗緢灏忕殑 J_opt锛屽綋浣滄敹鏁?if (`rc'==430) {
    capture confirm scalar J_opt
    if (_rc==0 & scalar(J_opt) < 1e-8) {
        di as txt "Flat region; treat as converged because J_opt is tiny."
        scalar gmm_conv = 1
        local rc 0
    }
}

if (`rc'==0) {
    capture confirm scalar gmm_conv
    if (_rc==0 & scalar(gmm_conv)==1) {
        matrix b0 = beta_lin
        local have_b0 1
        mata: st_local("have_b0","`have_b0'")
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
    gen b_m  = b[4,1]
    gen b_x   = b[5,1]
    gen J_unit  = J_unit
    gen J_opt   = J_opt
    gen J_df    = J_df
    gen J_p     = J_p
    gen N       = `Nobs'
    compress
    save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace
restore


tempname H
tempfile bootres
local failed = 0
postfile `H' rep double(b_const b_l b_k b_m b_x) using "`bootres'", replace

set seed 20250830
local B = 8



forvalues r = 1/`B' {
    preserve
        quietly bsample, cluster(firmid) idcluster(newfid)

        // 閲嶅缓闈㈡澘
        replace firmid = newfid
        xtset firmid year

        // T>=2锛岀‘淇濇湁婊炲悗
        by firmid: gen byte __T = _N
        keep if __T >= 2
        drop __T

        count
        if (r(N)==0) {
            restore
            continue
        }

        // 姣忔璋冪敤鍓嶆妸 have_b0 浼犵粰 Mata
        mata: st_local("have_b0","`have_b0'")
       * mata: st_local("GROUPNAME","`GROUPNAME'")
        // 浼拌
        capture noisily gmm2step_once

        // 鍙湪鏀舵暃鏃?post锛涙湭鏀舵暃璺宠繃
        if (_rc==0 & scalar(gmm_conv)==1) {
            post `H' (`r') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_m)) (r(b_x))

            // 婊氬姩璧风偣锛氭妸褰撳墠鎴愬姛瑙ｅ綋浣滀笅涓€杞捣鐐?            capture confirm matrix beta_lin
            if (_rc==0) {
                matrix b0 = beta_lin
                local have_b0 1
                mata: st_local("have_b0","`have_b0'")
            }
        }
        else {
            local ++failed
        }
    restore
    di as txt "bootstrap rep `r' done"
}
di as result "nonconverged reps skipped: `failed' / `B'"


postclose `H'


use "`bootres'", clear
compress
save "$DATA_WORK/gmm_boot_group_`GROUPNAME'.dta", replace

* ---------- Compute SEs and attach to point file ----------
quietly summarize b_const
local se_const = r(sd)
quietly summarize b_l
local se_l     = r(sd)
quietly summarize b_k
local se_k     = r(sd)
quietly summarize b_m
local se_m  = r(sd)
quietly summarize b_x
local se_x  = r(sd)


use "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", clear
gen se_const = `se_const'
gen se_l     = `se_l'
gen se_k     = `se_k'
gen se_m     = `se_m'
gen se_x   = `se_x'
replace J_df = scalar(J_df)
replace J_p = scalar(J_p)
order group b_const se_const b_l se_l b_k se_k b_m se_m b_x se_x J_unit J_opt J_df J_p N
compress
save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace


di as res "Done group `GROUPNAME'. Files written:"
di as res "  gmm_point_group_`GROUPNAME'.dta   (points + bootstrap SEs)"
di as res "  gmm_boot_group_`GROUPNAME'.dta    (draws)"

