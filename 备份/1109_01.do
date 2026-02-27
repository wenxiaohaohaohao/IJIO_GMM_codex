*******************************************************
* bootstrap0901_group.do
* Usage:
*   do "bootstrap0901_group.do"    // pooled {17,18,19}, IV spec of 18
*   do "bootstrap0901_group.do"    // pooled {39,40,41}, IV spec of 40
* Outputs (per group):
*   - gmm_point_group_<GROUP>.dta   (point + bootstrap SEs + J + N)
*   - gmm_boot_group_<GROUP>.dta    (bootstrap draws)

* [定义阶段]  先定义：Mata函数 + Stata的program  gmm2step_once
* [执行阶段]  for 每次bootstrap复制：
*              -> 调 gmm2step_once (Stata)
*              -> 调 mata:refresh_globals() (Mata)
*              -> 调 mata:run_two_step()    (Mata, 真正优化)
*              <- 结果回到 Stata, 存入 r()

*******************************************************

clear all
set more off
cd "D:\文章发表\欣昊\input markdown\IJIO\IJIO_GMM\1017\1022_non_hicks"
* 每个组开头都重置起点，并把 have_b0 传入 Mata
local have_b0 0                      

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
/*
merge 1:m firmid year using "C:\Users\xwang4\Downloads\nonneutraltartiff.dta"
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

* 1 是国企
replace firmcat = 1 if firmtype == 1

* 2、3、4 是外企
replace firmcat = 2 if inlist(firmtype, 2, 3, 4)

* 其他（即非 1、2、3、4）是私企
replace firmcat = 3 if !missing(firmtype) & !inlist(firmtype, 1, 2, 3, 4)
* 添加标签
label define firmcatlbl 1 "国企" 2 "外企" 3 "私企", replace
label values firmcat firmcatlbl
* -------- 2) 生成虚拟变量（基准：国企）--------
capture drop firmcat_*
tab firmcat, gen(firmcat_)

* 检查分类结果
tab firmcat
* -------- 2) 生成虚拟变量（基准：国企）--------
capture drop firmcat_*
tab firmcat, gen(firmcat_)


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
*drop if ratio<0.01   
*drop if ratio>0.98

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
xtset firmid year

capture confirm variable pft
if !_rc rename pft pi
capture confirm variable foreignprice
if !_rc rename foreignprice WX
capture confirm variable WX
if !_rc gen double wx = ln(WX)

* First stage  (ADD tariff as you asked)(先把关税删除掉，之后再说)
reg lratiofs k l wl x age lnmana i.firmcat i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2

* phi cubic (unchanged)
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmcat i.city i.year
// 回归（你的第一阶段）后：预测后只对有效样本赋值（避免 predict 因缺项产生的 173 个缺失混入）
predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "firststage.dta", replace

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

gen double lages   = L.es
gen double lages2q = L.es2q
gen double klages=k*lages

gen double kl = k*l
gen byte   const = 1

capture confirm variable const
if _rc gen byte const = 1
order firmid year, first
//drop if missing(r,l,k,phi,phi_lag,llag,mlag,ksqlag,lsqlag,klag,es,es2q,lages,lages2q,lnage,firmcat,lnmana)

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

* —— 1) 年龄的滞后 —— 
capture confirm variable lnagelag
if _rc gen double lnagelag = L.lnage

* —— 2) 企业性质哑变量的滞后（你已有 firmcat_1/2/3）——
capture confirm variable firmcat_2
if _rc {
    tab firmcat, gen(firmcat_)   // 你已有；此句只是兜底
}
capture confirm variable firmcat_2lag
if _rc gen byte firmcat_2lag = L.firmcat_2
capture confirm variable firmcat_3lag
if _rc gen byte firmcat_3lag = L.firmcat_3

* —— 3) 年度虚拟的滞后：与 X 里放的年份一一对应 —— 
levelsof year, local(yrs)
local base : word 1 of `yrs'   // 基准年，不放当期哑变量
foreach y of local yrs {
    if `y' != `base' {
        capture confirm variable dy`y'
        if _rc gen byte dy`y' = (year==`y')
        capture confirm variable dy`y'lag
        if _rc gen byte dy`y'lag = L.dy`y'
    }
}

drop if missing( ///
    r,  l,  k,  phi,  phi_lag,  ///
    llag,  klag,  mlag, lsqlag,  ksqlag,  ///
    es,  es2q,  lages,  lages2q,  ///
    lnage,  firmcat,  lnmana,  ///
      lnagelag,  firmcat_2lag,  firmcat_3lag,  ///
    dy2001lag,  dy2002lag,  dy2003lag,  dy2004lag,  dy2005lag,  dy2006lag,  dy2007lag )



*==================== Mata (two-step GMM; add tariff to CONSOL) ====================*
mata:
mata clear
Wg     = J(0,0,.)
OMEGA2 = J(0,1,.)
XI2    = J(0,1,.)

void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init
    // 当期 X（平移项）
    X = st_data(., ("const","l","k","lsq","ksq","m","es","es2q",
               "firmcat_2","firmcat_3",
                "dy2002","dy2003","dy2004","dy2005","dy2006","dy2007"))
    // 滞后 X_lag（逐列一一对应）
    X_lag = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag","lages","lages2q",
                    "firmcat_2lag","firmcat_3lag",
                    "dy2002lag","dy2003lag","dy2004lag","dy2005lag","dy2006lag","dy2007lag"))

/* IV sets by group name (no anchor needed) */
string scalar g
 g = st_global("GROUP_NAME")
     printf(">> [Mata] GROUPNAME seen: [%s]\n", g)
if (g!="G1_17_19" & g!="G2_39_41") {
        errprintf("Invalid GROUPNAME = [%s]; must be G1_17_19 or G2_39_41\n", g)
        _error(3499)
    }

if (g=="G1_17_19") {
    // 原先 anchor=18 的 IV（Kz=9）
	   Z = st_data(., ("const","firmcat_2","firmcat_3", "dy2001","dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","k", "llag","klag","mlag","lages","lages2q"))
    //Z = st_data(., ("const","llag","k","mlag","klag","l","lsq","lages","mlagk", "klages","firmcat_2","firmcat_3",
                              // "lnage","dy2001","dy2002","dy2003","dy2004","dy2005","dy2006","dy2007"))
	printf(">> Using IV: IV_anchor18_Kz9\n")
}
else  {
    // 原先 anchor=40 的 IV（Kz=9）
     Z = st_data(., ("const","llag","k","mlag","klag","l","lages","llagklag","lsq","mlagk","klages", "llagmlag", "ksq" ,"firmcat_2","firmcat_3","dy2001","dy2002","dy2003","dy2004","dy2005","dy2006","dy2007"))
	printf(">> Using IV: IV_anchor40_Kz9\n")
}

    PHI     = st_data(., "phi")
    PHI_lag = st_data(., "phi_lag")
    Y       = st_data(., "r")
    C       = st_data(., "const")

    // Controls（后续如要加关税再放进这里）
    CONSOL  = st_data(., ("lnage"))

    /* 起点：由 Stata 本地宏 have_b0 控制 */
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

 
    POOL = (C, OMEGA_lag)

    gb  = qrsolve(POOL, OMEGA)
    XI  = OMEGA - POOL * gb

    real scalar N;
	N = rows(Z);
    m    = quadcross(Z, XI) :/ N  ;    // ← NEW: 用样本平均
    crit = m' * Wg * m;
  // --- 早停：目标值极小就直接告诉优化器"梯度=0"，避免继续 line-search ---
    if (crit < 1e-8) {              // 阈值可 1e-14 ~ 1e-18 之间选
        if (todo>=1) g = J(1, cols(b), 0)
        return
    }

    /* 数值梯度：相对步长 + 中心差分（行向量） */
// --- 数值梯度：已知 cols(CONSOL)==0，因此 PO=(C, Oel) ---
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
        PO  = (C, Oel)
        XI2p = Oe - PO * qrsolve(PO, Oe)
        m2p  = quadcross(Z, XI2p) :/ N
        fplus = m2p' * Wg * m2p

        // -eps
        btmp    = b
        btmp[i] = b[i] - eps_i
        Oe  = PHI     - X     * btmp'
        Oel = PHI_lag - X_lag * btmp'
        PO  = (C, Oel)
        XI2m = Oe - PO * qrsolve(PO, Oe)
        m2m  = quadcross(Z, XI2m) :/ N
        fminus = m2m' * Wg * m2m

        gnum[i] = (fplus - fminus) / (2*eps_i)
    }

    g = gnum
}

}

void run_two_step()
{
	    // —— 初始化：就算失败也保证这些标量存在 —— 
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

    /* step 1: unit W  ——  NM */
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

    POOL1 = (C, OMEGA1_lag)

    XI1  = OMEGA1 - POOL1 * qrsolve(POOL1, OMEGA1)
    Mrow = Z :* (XI1 * J(1, cols(Z), 1))

    S    = (Mrow' * Mrow) :/ rows(Z)  // ← NEW: 也按 N 标准化

    sv   = svdsv(S)
    smin = min(sv)
    if (smin < 1e-6) lam = 1e-6 - smin; else lam = 0

    Wg = invsym(S + lam * I(Kz))
    if (rows(Wg)==0) Wg = pinv(S + lam * I(Kz))

/* step 2: optimal W —— 直接用 NM(d0) 主优化，最后再用 NR 小步数抛光 */
real scalar EPSJ
EPSJ = 1e-6 * rows(Z)    // 统一的"很小"门槛，你也可以用 1e-10 更宽松

// --- NM 主优化（无梯度） ---
S2 = optimize_init()
optimize_init_evaluator(S2, &GMM_DL_weighted())
optimize_init_evaluatortype(S2, "d0")        // ← 关键：NM 用 d0
optimize_init_which(S2, "min")
optimize_init_params(S2, b1)
optimize_init_technique(S2, "nm")
optimize_init_nmsimplexdeltas(S2, 0.03)      // 初始单纯形步长，按需 0.01~0.1 调
optimize_init_conv_maxiter(S2, 200)
optimize_init_conv_ptol(S2, 1e-6)
optimize_init_conv_vtol(S2, 1e-6)
// 小样本/自举循环里建议安静：把 "value" 改成 "none"
optimize_init_tracelevel(S2, "none")

b2    = optimize(S2)
J2    = optimize_result_value(S2)
conv2 = optimize_result_converged(S2)

// --- 如果目标已经极小，直接视为已收敛，跳过 NR ---
if (J2 <= EPSJ) {
    conv2 = 1
}

// --- 统一门槛：只要 J2 还大，就抛光（不看 conv2）---
if (J2 > EPSJ) {
    // 先 BFGS（稳）
    S2 = optimize_init()
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

    // 还不够，再 NR 少量步兜底
    if (J2 > EPSJ) {
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
   
    POOL2 = (C, OMEGA2_lag)

    g_bvec    = qrsolve(POOL2, OMEGA2_local)
    XI2_local = OMEGA2_local - POOL2 * g_bvec

    // ----- 维度健检 -----
    if (rows(Z)!=rows(X) | rows(Z)!=rows(PHI)) {
        errprintf("run_two_step(): row mismatch: rows(Z)=%f, rows(X)=%f, rows(PHI)=%f\n", rows(Z), rows(X), rows(PHI))
        _error(3200)
    }
    if (cols(Wg)!=cols(Z) | rows(Wg)!=cols(Z)) {
        // 若权重矩阵没被正确设好，就退回单位权重，不让维度炸
        Wg = I(cols(Z))
    }

    // 样本平均矩
    real colvector m_unit
    m_unit = quadcross(Z, OMEGA1 - (  (C, OMEGA1_lag) * qrsolve((C, OMEGA1_lag), OMEGA1 ) )) :/ rows(Z)
    m2     = quadcross(Z, XI2_local) :/ rows(Z)

    // ----- 保存中间结果（和你原来一致） -----
    st_matrix("beta_lin_step1", b1')
    st_matrix("beta_lin",        b2')
    st_matrix("g_b",             g_bvec)
    st_matrix("moments_unit",    m_unit)
    st_matrix("moments_opt",     m2)
    st_matrix("W_opt",           Wg)
    st_numscalar("gmm_conv1",    conv1)
    st_numscalar("gmm_conv2",    conv2)

// ===== 先算 J 要素，再判定收敛 =====
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


    // 回写给全局（供外面取用）
    OMEGA2 = OMEGA2_local
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
    return scalar b_lsq  = b[4,1]
    return scalar b_ksq  = b[5,1]
    return scalar b_m    = b[6,1]
    return scalar b_es   = b[7,1]
    return scalar b_essq = b[8,1]

    // 按你在 Mata 里 CONSOL 的顺序，gb[1,9] = lnage；gb[1,10] = firmtype
    return scalar b_lnage    = b[9,1]
    return scalar b_firmcat_2 = b[10,1]
    return scalar b_firmcat_3 = b[11,1]
	
	
end



* 初始没有 b0
* —— 全样本先跑一次，取起点 b0，并保存点估 —— *
local have_b0 0
mata: st_local("have_b0","`have_b0'")
*mata: st_local("GROUPNAME","`GROUPNAME'")          
capture noisily gmm2step_once
local rc = _rc

* r(430) 兜底：若 Mata 已经写回了很小的 J_opt，当作收敛
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

// full-sample 成功后，立刻抓取两个控制项系数
local b_lnage_hat     = r(b_lnage)
local b_firmcat2_hat  = r(b_firmcat_2)
local b_firmcat3_hat  = r(b_firmcat_3)



* === 输出 firm-level omega_hat / xi_hat（全样本） ===
capture drop omega_hat xi_hat
gen double omega_hat = .
gen double xi_hat    = .

* 把 Mata 里的 OMEGA2、XI2 写回当前样本行（与 refresh_globals 使用的样本严格对齐）
mata: st_store(., ("omega_hat","xi_hat"), (OMEGA2, XI2))

*（可选）基本健检：不应有缺失
assert !missing(omega_hat, xi_hat)

* 只留关键面板键与结果，按组名输出一个文件
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
	    // 只写 lnage 与 firmtype 两个控制项的系数（一次回归点估）=====
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


tempname H
tempfile bootres
local failed = 0
postfile `H' rep double(b_const b_l b_k b_lsq b_ksq b_m b_es b_essq) using "`bootres'", replace

set seed 20250830
local B = 1



forvalues r = 1/`B' {
    preserve
        quietly bsample, cluster(firmid) idcluster(newfid)

        // 重建面板
        replace firmid = newfid
        xtset firmid year

        // T>=2，确保有滞后
        by firmid: gen byte __T = _N
        keep if __T >= 2
        drop __T

        count
        if (r(N)==0) {
            restore
            continue
        }

        // 每次调用前把 have_b0 传给 Mata
        mata: st_local("have_b0","`have_b0'")
       * mata: st_local("GROUPNAME","`GROUPNAME'")
        // 估计
        capture noisily gmm2step_once

        // 只在收敛时 post；未收敛跳过
        if (_rc==0 & scalar(gmm_conv)==1) {
            post `H' (`r') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_lsq)) (r(b_ksq)) (r(b_m)) (r(b_es)) (r(b_essq))

            // 滚动起点：把当前成功解当作下一轮起点
            capture confirm matrix beta_lin
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
save "gmm_boot_group_`GROUPNAME'.dta", replace

* ---------- Compute SEs and attach to point file ----------
quietly summarize b_const
local se_const = r(sd)
quietly summarize b_l
local se_l     = r(sd)
quietly summarize b_k
local se_k     = r(sd)
quietly summarize b_lsq
local se_lsq   = r(sd)
quietly summarize b_ksq
local se_ksq   = r(sd)
quietly summarize b_m
local se_m     = r(sd)
quietly summarize b_es
local se_es    = r(sd)
quietly summarize b_essq
local se_essq  = r(sd)

use "gmm_point_group_`GROUPNAME'.dta", clear
gen se_const = `se_const'
gen se_l     = `se_l'
gen se_k     = `se_k'
gen se_lsq   = `se_lsq'
gen se_ksq   = `se_ksq'
gen se_m     = `se_m'
gen se_es    = `se_es'
gen se_essq  = `se_essq'
replace J_df = scalar(J_df)
replace J_p = scalar(J_p)
order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq b_m se_m b_es se_es b_essq se_essq b_lnage b_firmcat_2 b_firmcat_3  J_unit J_opt J_df J_p N

compress
save "gmm_point_group_`GROUPNAME'.dta", replace


di as res "Done group `GROUPNAME'. Files written:"
di as res "  gmm_point_group_`GROUPNAME'.dta   (points + bootstrap SEs)"
di as res "  gmm_boot_group_`GROUPNAME'.dta    (draws)"
