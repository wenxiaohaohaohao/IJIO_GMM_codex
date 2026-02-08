*******************************************************
* bootstrap0901_group.do
* Usage:
*   do "bootstrap0901_group.do"    // pooled {17,18,19}, IV spec of 18
*   do "bootstrap0901_group.do"    // pooled {39,40,41}, IV spec of 40
* Outputs (per group):
*   - gmm_point_group_<GROUP>.dta   (point + bootstrap SEs + J + N)
*   - gmm_boot_group_<GROUP>.dta    (bootstrap draws)
*******************************************************
clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"

* 使用 global 传递起点状态，供 Mata 读取
global have_b0_mata 0    // 0=没有已有起点，1=已有收敛起点  * ——1120添加 —— *

* === 仅从全局读取组名，并做校验 ===
if ("$GROUP_NAME"=="") {
    di as err "ERROR: global GROUP_NAME is empty. Set it before calling this do-file."
    exit 3499
}
if ("$GROUP_NAME"!="G1_17_19" & "$GROUP_NAME"!="G2_39_41") {
    di as err "ERROR: invalid GROUP_NAME=[$GROUP_NAME]. Must be G1_17_19 or G2_39_41."
    exit 3499
}

* 在本 do 的作用域内生成一个 local，便于后面文件名/筛选使用
local GROUPNAME "$GROUP_NAME"
di as txt "DBG: GROUP_NAME(global) = [$GROUP_NAME] ; GROUPNAME(local) = `GROUPNAME'"

* -------- Load & merge -------- *
use "junenewg_0902", clear

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

* -------- 你的数据处理与构造部分（保持不变）-------- *
gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

drop if domesticint <= 0
drop if 营业收入合计千元 < 40

gen double R = 工业总产值_当年价格千元 * 1000 / e

rename 固定资产合计千元 K
drop if K < 30
rename 全部从业人员年平均人数人 L
replace L = 年末从业人员合计人 if year==2003
drop if L < 8

rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

gen double WL = 应付工资薪酬总额千元 * 1000 / e

* 生成企业性质大类变量
gen firmcat = . 
replace firmcat = 1 if firmtype == 1
replace firmcat = 2 if inlist(firmtype, 2, 3, 4)
replace firmcat = 3 if missing(firmcat)
label define firmcatlbl 1 "国企" 2 "外企" 3 "私企", replace
label values firmcat firmcatlbl

capture drop firmcat_*
tab firmcat, gen(firmcat_)

tab firmcat

capture confirm variable firmtotalq
if !_rc rename firmtotalq X

* Merge investment deflator and reconstruct capital
merge m:1 year using "Brandt-Rawski investment deflator.dta", nogen
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

rename 工业中间投入合计千元 MI
rename 管理费用千元 Mana

gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0
capture ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen double lratiofs = lnR - lnM

gen ratio = importint/(domesticint+importint)

gen inputp = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF = importint/einputp

replace 开业成立时间年 = . if 开业成立时间年==0
gen age   = year - 开业成立时间年 + 1
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

* First stage （暂时不加关税）
reg lratiofs k l wl x age lnmana i.firmcat i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2

* phi cubic (unchanged)
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmcat i.city i.year
predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "firststage.dta", replace

* 保留最长连续段 >= 2 年，删除首年不保留（因为后面有 lag）
sort firmid year
isid firmid year, sort
di "✅ Data sorted and verified: unique firm-year combinations"

by firmid: gen gap = year - L.year
by firmid: gen seqblock = (gap != 1 | missing(gap))
by firmid: replace seqblock = sum(seqblock)
bys firmid seqblock: gen seg_len = _N
bys firmid: egen max_seg_len = max(seg_len)
keep if max_seg_len >= 2
drop gap seqblock seg_len max_seg_len

bys firmid: gen nobs_firm = _N
tab nobs_firm, missing
sum nobs_firm, detail
drop nobs_firm

* 生成滞后项
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
gen double klages  = k*lages

gen double kl = k*l
gen byte   const = 1
capture confirm variable const
if _rc gen byte const = 1
order firmid year, first

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

* —— 1) 年龄的滞后 —— 
capture confirm variable lnagelag
if _rc {
    gen double lnagelag = L.lnage
    di "✅ Created: lnagelag (lagged firm age)"
}

drop if missing(r, l, k, phi, phi_lag, llag, klag, mlag, lsqlag, ksqlag, ///
    lsq, ksq, m, es, es2q, lages, lages2q, lnage, firmcat, lnmana, ///
    lnagelag, firmcat_2, firmcat_3, dy2002-dy2007, klages, mlagxlag)

*==================== Mata (two-step GMM) ====================*
mata:
mata clear

/* 初始化全局矩阵（用于 st_store 回写时保证存在） */
Wg     = J(0,0,.)      // 目前未使用，但保留不冲突
OMEGA2 = J(0,1,.)
XI2    = J(0,1,.)

void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init, Wg_opt

    X       = st_data(., ("const","l","k","lsq","ksq","m","es","es2q"))
    X_lag   = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag","lages","lages2q"))

    string scalar g
    g = st_global("GROUP_NAME")
    printf(">> [Mata] GROUPNAME seen: [%s]\n", g)
    if (g!="G1_17_19" & g!="G2_39_41") {
        errprintf("Invalid GROUPNAME = [%s]; must be G1_17_19 or G2_39_41\n", g)
        _error(3499)
    }

    if (g=="G1_17_19") {
        Z = st_data(., ("const","llag","k","mlag","klag","l","lsq","lages","mlagk","klages"))
        printf(">> Using IV: IV_anchor18_Kz9\n")
    }
    else  {
        Z = st_data(., ("const","llag","k","mlag","klag","l","lages","llagklag","lsq","mlagk","klages","llagmlag","ksq"))
        printf(">> Using IV: IV_anchor40_Kz9\n")
    }

    // 标准化 Z
    real rowvector mu, zs
    mu = colsum(Z) :/ rows(Z)
    Z  = Z :- mu
    zs = sqrt(colsum(Z:^2) :/ rows(Z)) :+ 1e-12
    Z  = Z :/ zs
	
    PHI     = st_data(., "phi")
    PHI_lag = st_data(., "phi_lag")
    Y       = st_data(., "r")
    C       = st_data(., "const")

    // Controls
    CONSOL  = st_data(., ("dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","lnage","firmcat_2","firmcat_3"))

    // 起点：用 Stata global have_b0_mata 控制
    real scalar use_b0
    use_b0 = strtoreal(st_global("have_b0_mata"))   // 从 global 读取  * ——1120添加 —— *
    printf(">> [Mata] have_b0_mata = %f\n", use_b0)
    if (use_b0 == 1) {
        beta_init = st_matrix("b0")'
        printf(">> Using previous converged beta as starting point\n")
        if (cols(beta_init) != cols(X)) {
            printf(">> WARN: dimensions mismatch (beta_init=%f, X=%f). Recomputing OLS start.\n", cols(beta_init), cols(X))
            beta_init = (invsym(X'X) * (X'Y))'
        }
    }
    else {
        beta_init = (invsym(X'X) * (X'Y))'
        printf(">> Using OLS as starting point\n")
    }

    // 初始化权重矩阵
    Wg_opt = J(0,0,.)	
}

void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg, Wg_opt

    real colvector OMEGA, OMEGA_lag, XI, gb, m
    real matrix PO
    real scalar N, crit_val

    OMEGA     = PHI     - X     * b'
    OMEGA_lag = PHI_lag - X_lag * b'

    if (cols(CONSOL)>0) PO = (C, OMEGA_lag, CONSOL)
    else                PO = (C, OMEGA_lag)

    gb  = qrsolve(PO, OMEGA)
    XI  = OMEGA - PO * gb

    N       = rows(Z)
    m       = quadcross(Z, XI) :/ N
    crit_val = m' * Wg_opt * m
	
    // 早停
    if (crit_val < 1e-10 * N) {
        crit = crit_val
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }
    
    crit = crit_val

    // 数值梯度
    if (todo>=1) {
        real scalar i, eps_i, crit_plus, crit_minus
        real rowvector gnum, btmp
        real colvector Oe, Oel, XI2p, XI2m, m2p, m2m

        gnum = J(1, cols(b), .)

        for (i=1; i<=cols(b); i++) {
            eps_i = max(1e-6, 1e-6 * abs(b[i]))

            // +eps
            btmp    = b
            btmp[i] = b[i] + eps_i
            Oe  = PHI     - X     * btmp'
            Oel = PHI_lag - X_lag * btmp'
            PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
            gb  = qrsolve(PO, Oe)
            XI2p = Oe - PO*gb
            m2p  = quadcross(Z, XI2p):/ N
            crit_plus = m2p' * Wg_opt * m2p

            // -eps
            btmp    = b
            btmp[i] = b[i] - eps_i
            Oe  = PHI     - X     * btmp'
            Oel = PHI_lag - X_lag * btmp'
            PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
            gb  = qrsolve(PO, Oe)
            XI2m = Oe - PO*gb
            m2m  = quadcross(Z, XI2m):/ N
            crit_minus = m2m' * Wg_opt * m2m

            gnum[i] = (crit_plus - crit_minus) / (2*eps_i)
        }

        g = gnum
    }
}

void run_two_step()
{
    // 保证标量存在
    st_numscalar("gmm_conv1", 0)
    st_numscalar("gmm_conv2", 0)
    st_numscalar("gmm_conv",  0)
    st_numscalar("J_unit",    .)
    st_numscalar("J_opt",     .)
    st_numscalar("J_df",      .)
    st_numscalar("J_p",       .)

    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg, OMEGA2, XI2, beta_init, Wg_opt

    real scalar Kz, Kx, J1, J2, lam, conv1, conv2, smin, smax, cond, EPSJ, df, jp
    real rowvector b1, b2, b2_nr
    real colvector OMEGA1, OMEGA1_lag, XI1, OMEGA2_local, OMEGA2_lag, XI2_local, gb_vec, m_unit, m_opt, svals
    real matrix POOL1, Mrow, S, POOL2
    real scalar N, Junit, Jopt, J2_nr, conv2_nr

    // 样本量与维度检查
    N = rows(Z)
    st_numscalar("Nobs", N)
    printf("\n>> [GMM] Starting two-step estimation with N=%f observations\n", N)

    Kz = cols(Z)
    Kx = cols(X)
    if (Kz < Kx) {
        errprintf("ERROR: Not enough instruments (Kz=%f < Kx=%f). Cannot identify model.\n", Kz, Kx)
        _error(3498)
    }

    // ===== Step 1: Unit weight matrix (I) =====
    Wg_opt = I(Kz)
    printf(">> Step 1: GMM with unit weight matrix (NM optimization)\n")

    real scalar S1_handle
    S1_handle = optimize_init()
    optimize_init_evaluator(S1_handle, &GMM_DL_weighted())
    optimize_init_evaluatortype(S1_handle, "d0")
    optimize_init_which(S1_handle, "min")
    optimize_init_params(S1_handle, beta_init)
    optimize_init_technique(S1_handle, "nm")
    optimize_init_nmsimplexdeltas(S1_handle, J(1, cols(beta_init), 0.1))
    optimize_init_conv_maxiter(S1_handle, 500)
    optimize_init_conv_ptol(S1_handle, 1e-5)
    optimize_init_conv_vtol(S1_handle, 1e-5)
    optimize_init_tracelevel(S1_handle, "none")

    b1 = J(1, Kx, .)
    b1    = optimize(S1_handle)
    J1    = optimize_result_value(S1_handle)
    conv1 = optimize_result_converged(S1_handle)

    printf("   Step 1: J1 = %12.6f, converged = %f\n", J1, conv1)
    st_numscalar("gmm_conv1", conv1)

    if (!conv1) {
        printf("   Step 1 did not converge. Trying smaller simplex deltas...\n")
        optimize_init_nmsimplexdeltas(S1_handle, J(1, cols(beta_init), 0.01))
        optimize_init_params(S1_handle, b1)

        b1    = optimize(S1_handle)
        J1    = optimize_result_value(S1_handle)
        conv1 = optimize_result_converged(S1_handle)

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

    S    = (Mrow' * Mrow) :/ rows(Z)

    // S 的条件数与 ridge 正则化
    svals = svdsv(S)
    smin  = min(svals)
    smax  = max(svals)
    cond  = smax / max(smin, 1e-12)

    lam = 0
    if (cond > 1e6) {
        lam = max(1e-6, (1e-6 * smax))
        printf("   WARN: S matrix ill-conditioned (cond=%9.2e). Adding ridge lambda=%9.2e\n", cond, lam)
    }
    else {
        printf("   S matrix condition number: %9.2e (good)\n", cond)
    }

    if (lam > 0) {
        Wg_opt = invsym(S + lam * I(Kz))
    }
    else {
        Wg_opt = invsym(S)
    }
    st_matrix("W_opt", Wg_opt)

    // ===== Step 2: GMM with optimal weight matrix =====
    printf(">> Step 2: GMM with optimal weight matrix\n")
    EPSJ = 1e-8 * N  

    real scalar S2_handle
    S2_handle = optimize_init()
    optimize_init_evaluator(S2_handle, &GMM_DL_weighted())
    optimize_init_evaluatortype(S2_handle, "d0")
    optimize_init_which(S2_handle, "min")
    optimize_init_params(S2_handle, b1)
    optimize_init_technique(S2_handle, "bfgs")
    optimize_init_conv_maxiter(S2_handle, 200)
    optimize_init_conv_ptol(S2_handle, 1e-6)
    optimize_init_conv_vtol(S2_handle, 1e-6)
    optimize_init_tracelevel(S2_handle, "none")

    b2 = J(1, Kx, .)
    b2    = optimize(S2_handle)
    J2    = optimize_result_value(S2_handle)
    conv2 = optimize_result_converged(S2_handle)

    printf("   Step 2 (BFGS): J2 = %12.6f, converged = %f\n", J2, conv2)

    if (!conv2) {
        printf("   BFGS did not converge. Switching to Nelder–Mead...\n")

        S2_handle = optimize_init()
        optimize_init_evaluator(S2_handle, &GMM_DL_weighted())
        optimize_init_evaluatortype(S2_handle, "d0")
        optimize_init_which(S2_handle, "min")
        optimize_init_params(S2_handle, b1)
        optimize_init_technique(S2_handle, "nm")
        optimize_init_nmsimplexdeltas(S2_handle, J(1, cols(b1), 0.01))
        optimize_init_conv_maxiter(S2_handle, 500)
        optimize_init_conv_ptol(S2_handle, 1e-6)
        optimize_init_conv_vtol(S2_handle, 1e-6)
        optimize_init_tracelevel(S2_handle, "none")

        b2    = optimize(S2_handle)
        J2    = optimize_result_value(S2_handle)
        conv2 = optimize_result_converged(S2_handle)

        printf("   Step 2 (NM):   J2 = %12.6f, converged = %f\n", J2, conv2)

        if (!conv2) {
            printf("   WARNING: NM did not converge. Will still try NR polishing if needed.\n")
        }
    }

    if ( ( !conv2 | J2 > EPSJ ) & rows(b2)==1 & cols(b2)==Kx ) {
        printf("   Trying Newton–Raphson polishing...\n")

        S2_handle = optimize_init()
        optimize_init_evaluator(S2_handle, &GMM_DL_weighted())
        optimize_init_evaluatortype(S2_handle, "d0")
        optimize_init_which(S2_handle, "min")
        optimize_init_params(S2_handle, b2)
        optimize_init_technique(S2_handle, "nr")
        optimize_init_conv_maxiter(S2_handle, 15)
        optimize_init_conv_ptol(S2_handle, 1e-7)
        optimize_init_conv_vtol(S2_handle, 1e-7)
        optimize_init_tracelevel(S2_handle, "none")

        b2_nr    = optimize(S2_handle)
        J2_nr    = optimize_result_value(S2_handle)
        conv2_nr = optimize_result_converged(S2_handle)

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

    // ===== 计算最终统计量 =====
    OMEGA2     = PHI     - X     * b2'
    OMEGA2_lag = PHI_lag - X_lag * b2'

    if (cols(CONSOL)>0) {
        POOL2 = (C, OMEGA2_lag, CONSOL)
    }
    else {
        POOL2 = (C, OMEGA2_lag)
    }

    gb_vec = qrsolve(POOL2, OMEGA2)
    XI2    = OMEGA2 - POOL2 * gb_vec

    m_unit = quadcross(Z, XI1) :/ N   // 基于 step1 残差
    m_opt  = quadcross(Z, XI2) :/ N   // 基于 step2 残差

    Junit = N * quadcross(m_unit, m_unit)
    Jopt  = N * quadcross(m_opt, Wg_opt * m_opt)

    df = Kz - Kx
    jp = .
    if (df > 0) jp = chi2tail(df, Jopt)

    printf("\n>> GMM Results:\n")
    printf("   J-stat (unit weight): %12.4f\n", Junit)
    printf("   J-stat (opt weight) : %12.4f  (df=%g, p=%6.4f)\n", Jopt, df, jp)
    printf("   Converged (step1): %f, (step2): %f\n", conv1, conv2)

    // 保存结果到 Stata
    st_matrix("beta_lin_step1", b1')
    st_matrix("beta_lin",        b2')
    st_matrix("g_b",             gb_vec)
    st_matrix("moments_unit",    m_unit')   // 1×Kz
    st_matrix("moments_opt",     m_opt')
    st_matrix("W_opt",           Wg_opt)

    st_numscalar("J_unit",   Junit)
    st_numscalar("J_opt",    Jopt)
    st_numscalar("J_df",     df)
    st_numscalar("J_p",      jp)
    st_numscalar("gmm_conv", (conv1 & conv2))

    st_store(., "OMEGA2", OMEGA2)
    st_store(., "XI2",    XI2)
}
end

* ---------- Bootstrap (cluster by firmid) ----------

program define gmm2step_once, rclass
    version 18
    syntax [, rep(integer 0)]
    
    timer clear 1
    timer on 1
    
    capture mata: refresh_globals()
    if _rc {
        di as err "ERROR in refresh_globals(): rc=`_rc'"
        exit _rc
    }
    
    capture mata: run_two_step()
    if _rc {
        di as err "ERROR in run_two_step(): rc=`_rc'"
        exit _rc
    }
    
    capture confirm scalar gmm_conv
    if _rc {
        di as err "gmm_conv not returned"
        exit 498
    }
    
    if scalar(gmm_conv) != 1 {
        di as txt "WARNING: GMM did not fully converge (gmm_conv=`=scalar(gmm_conv)')"
    }
    
    capture confirm matrix beta_lin
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
    
    capture confirm matrix g_b
    if _rc {
        di as err "g_b not returned"
        exit 498
    }
    
    matrix gb = g_b
    return scalar b_lnage     = gb[9,1]
    return scalar b_firmcat_2 = gb[10,1]
    return scalar b_firmcat_3 = gb[11,1]
    
    capture confirm scalar J_opt
    if !_rc return scalar J_opt = scalar(J_opt)
    
    capture confirm scalar J_p
    if !_rc return scalar J_p = scalar(J_p)
    
    timer off 1
    timer list 1
    return scalar time = r(t1)
    
    di as txt "Rep `rep': completed in `=r(t1)' sec. J_opt=`=scalar(J_opt)'"
end

* —— 全样本先跑一次，取起点 b0，并保存点估 —— *
global have_b0_mata 0  // 初始无起点

di as text _n(2) "{hline 80}"
di as text "Running full-sample GMM to get starting values and point estimates"
di as text "{hline 80}"

capture noisily gmm2step_once
local rc = _rc

if (`rc'==430) {
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
        global have_b0_mata 1
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

local b_lnage_hat     = r(b_lnage)
local b_firmcat2_hat  = r(b_firmcat_2)
local b_firmcat3_hat  = r(b_firmcat_3)

* === 保存全样本残差 ===
capture drop OMEGA2 XI2
gen double OMEGA2 = .
gen double XI2    = .
mata: st_store(., ("OMEGA2","XI2"), st_data(., ("OMEGA2","XI2")))

capture drop omega_hat xi_hat
gen double omega_hat = OMEGA2
gen double xi_hat    = XI2

qui count if missing(omega_hat, xi_hat)
if r(N) > 0 {
    di as txt "WARNING: `r(N)' missing values in omega_hat/xi_hat"
}

preserve
    keep firmid year cic2 omega_hat xi_hat
    gen str10 group = "`GROUPNAME'"
    order group firmid year cic2 omega_hat xi_hat
    compress
    save "omega_xi_group_`GROUPNAME'.dta", replace
restore

* —— 现在保存全样本点估 —— *
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
    save "gmm_point_group_`GROUPNAME'.dta", replace
restore

* ===== 在全样本估计后立即展示核心结果，方便检查 Step1 / Step2 / J =====  * ——1120添加 —— *
matrix list beta_lin_step1                                              * ——1120添加 —— *
matrix list beta_lin                                                    * ——1120添加 —— *
matrix list moments_unit                                                * ——1120添加 —— *
matrix list moments_opt                                                 * ——1120添加 —— *
scalar list J_unit J_opt J_df J_p gmm_conv                              * ——1120添加 —— *
display as text "J_opt = " J_opt "  (df = " J_df ", p = " J_p ")"        * ——1120添加 —— *

* —— Bootstrap 循环 —— *
di as text _n(2) "{hline 80}"
di as text "Starting bootstrap estimation (clustered by firmid)"
di as text "{hline 80}"

tempname H
tempfile bootres
local failed = 0
local total_time = 0

set seed 20250830
local B = 2  // 调试用，正式运行请设为较大值

tempfile failures
postfile failures rep reason using "`failures'", replace

postfile `H' rep double(b_const b_l b_k b_lsq b_ksq b_m b_es b_essq b_lnage b_firmcat_2 b_firmcat_3 J_opt time) ///
    using "`bootres'", replace

forvalues r = 1/`B' {
    di as text _n "Bootstrap rep `r'/`B'"
    
    preserve
        quietly bsample, cluster(firmid) idcluster(newfid)
        gen long orig_firmid = firmid
        replace firmid = newfid
        xtset firmid year
        
        by firmid: gen byte __T = _N
        keep if __T >= 2
        drop __T
        
        qui count
        local N_bs = r(N)
        di as text "  Sample size after keeping T>=2: `N_bs'"
        
        if (`N_bs' < 50) {
            di as txt "  WARNING: Very small sample (`N_bs' obs). May not converge."
        }
        
        * 此处不再需要额外传递 have_b0_mata，直接用 Stata global 给 Mata 用即可  * ——1120添加 —— *
        
        capture noisily gmm2step_once, rep(`r')
        local rc = _rc
        
        if (`rc' == 0) {
            capture confirm scalar gmm_conv
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
        
        if (`rc' == 0 & scalar(gmm_conv) == 1) {
            post `H' (`r') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_lsq)) (r(b_ksq)) (r(b_m)) ///
                   (r(b_es)) (r(b_essq)) (r(b_lnage)) (r(b_firmcat_2)) (r(b_firmcat_3)) ///
                   (r(J_opt)) (r(time))
            
            capture confirm matrix beta_lin
            if (_rc == 0) {
                matrix b0 = beta_lin
                global have_b0_mata 1
            }
            else {
                di as txt "  WARNING: beta_lin not available, cannot update starting point"
            }
            
            local total_time = `total_time' + r(time)
            di as result "  SUCCESS: rep `r' converged in `=r(time)' sec"
        }
        else {
            local ++failed
            post failures (`r') ("`reason'")
            di as error "  FAILED: rep `r' - `reason'"
        }
    restore
}

postclose `H'
postclose failures

di as result _n(2) "Bootstrap completed:"
di as result "  Total reps: `B'"
di as result "  Successful: `=`B'-`failed''"
di as result "  Failed: `failed'"
di as result "  Avg time per rep: `=`total_time'/(`B'-`failed')' sec"

use "`failures'", clear
if _N > 0 {
    list, noobs
    save "bootstrap_failures_`GROUPNAME'.dta", replace
}

use "`bootres'", clear
if _N == 0 {
    di as err "No successful bootstrap replications. Cannot compute SEs."
    exit 430
}

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

use "gmm_point_group_`GROUPNAME'.dta", clear
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
gen boot_reps = `=`B'-`failed''
gen avg_time = `=`total_time'/(`B'-`failed')'

replace J_df = scalar(J_df)
replace J_p = scalar(J_p)
order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq b_m se_m b_es se_es b_essq se_essq ///
      b_lnage se_lnage b_firmcat_2 se_firmcat_2 b_firmcat_3 se_firmcat_3 ///
      J_unit J_opt J_df J_p N boot_reps avg_time

compress
save "gmm_point_group_`GROUPNAME'.dta", replace

use "`bootres'", clear
compress
save "gmm_boot_group_`GROUPNAME'.dta", replace

di as res _n(2) "{hline 80}"
di as res "Done group `GROUPNAME'. Files written:"
di as res "  gmm_point_group_`GROUPNAME'.dta   (points + bootstrap SEs + diagnostics)"
di as res "  gmm_boot_group_`GROUPNAME'.dta    (draws)"
di as res "  omega_xi_group_`GROUPNAME'.dta   (firm-level residuals)"
if `failed' > 0 di as res "  bootstrap_failures_`GROUPNAME'.dta (failure reasons)"
di as res "{hline 80}"

local end_time = c(current_time)
display as text "INFO: Script finished at `end_time'"
