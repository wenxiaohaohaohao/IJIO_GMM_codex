*******************************************************
* 目的：按模块清晰整理两步 GMM + bootstrap 程序
* 说明：逻辑与你当前版本等价，只是：
*   1) 加了模块化大标题和注释；
*   2) 线性 IV + J 分解打印移入可选诊断模块；
*   3) 修正 G2_39_41 线性 IV 诊断中的小笔误（不影响 GMM）；
*******************************************************

*------------------------------------------------------
* 模块 0：环境设置 & 组名检查（对应你原来开头部分）
*------------------------------------------------------
clear
set more off
set trace off
capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
if ("$CODE"=="") global CODE "$ROOT/code"
if ("$DATA_RAW"=="") global DATA_RAW "$ROOT/data/raw"
if ("$DATA_WORK"=="") global DATA_WORK "$ROOT/data/work"
if ("$RES_DATA"=="") global RES_DATA "$ROOT/results/data"
if ("$RES_FIG"=="") global RES_FIG "$ROOT/results/figures"
if ("$RES_LOG"=="") global RES_LOG "$ROOT/results/logs"


cd "$ROOT"

* 可选：是否运行诊断模块（线性 IV + J 分解打印）
local RUN_DIAG 0
local RUN_DIAG 0
if ("$RUN_DIAG"!="") local RUN_DIAG = real("$RUN_DIAG")

local RUN_POINT_ONLY 0
if ("$RUN_POINT_ONLY"!="") local RUN_POINT_ONLY = real("$RUN_POINT_ONLY")

local RUN_BOOT 1
if ("$RUN_BOOT"!="") local RUN_BOOT = real("$RUN_BOOT")
if (`RUN_POINT_ONLY'==1) local RUN_BOOT 0

* Optional robust optimizer mode for fragile IV sets (A2/A3)
local ROBUST_INIT 0
if ("$ROBUST_INIT"!="") local ROBUST_INIT = real("$ROBUST_INIT")
global ROBUST_INIT "`ROBUST_INIT'"

* Optional IV override (space-separated var list), by group
if ("$IV_Z_G1"=="") global IV_Z_G1 ""
if ("$IV_Z_G2"=="") global IV_Z_G2 ""

* IV set switch for V1 diagnostics / robustness gate (A | B | C | A1 | A2 | A3)
local IV_SET "A"
if ("$IV_SET"!="") local IV_SET = upper("$IV_SET")
if !inlist("`IV_SET'","A","B","C","A1","A2","A3") {
    di as err "ERROR: invalid IV_SET=[`IV_SET']; must be A, B, C, A1, A2, or A3."
    exit 198
}
global IV_SET "`IV_SET'"
di as txt "RUN SWITCH: RUN_POINT_ONLY=`RUN_POINT_ONLY', RUN_BOOT=`RUN_BOOT', RUN_DIAG=`RUN_DIAG', IV_SET=`IV_SET', ROBUST_INIT=`ROBUST_INIT'"
di as txt "IV overrides: G1=[$IV_Z_G1] ; G2=[$IV_Z_G2]"

* === 从全局读取 GROUP_NAME，并做合法性检查 ===
if ("$GROUP_NAME"=="") {
    di as err "ERROR: global GROUP_NAME is empty. Set it before calling this do-file."
    exit 3499
}
if ("$GROUP_NAME"!="G1_17_19" & "$GROUP_NAME"!="G2_39_41") {
    di as err "ERROR: invalid GROUP_NAME=[$GROUP_NAME]. Must be G1_17_19 or G2_39_41."
    exit 3499
}

local GROUPNAME "$GROUP_NAME"
di as txt "DBG: GROUP_NAME(global) = [$GROUP_NAME] ; GROUPNAME(local) = `GROUPNAME'"

* -------- 载入原始面板数据 -------- *
use "$DATA_RAW/junenewg_0902", clear

* -------- 按组别筛选行业（对应原 Group filter 段） -------- *
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

confirm numeric variable year
if _rc destring year, replace ignore(" -/,")
xtset firmid year

*======================================================
* 模块 1：数据清理与核心变量构造
*   对应你原先从"gen double e = ."到"save firststage.dta"
*   作用：构造 R,K,L,Q,W, firmcat，重建资本 K_current，
*         生成 ln 变量、winsor、第一阶段 OLS + φ。
*======================================================

* -------- 1.1 汇率 & 初步样本过滤 -------- *
gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

drop if domesticint <= 0
drop if 营业收入合计千元 < 40

* -------- 1.2 产出 R、资本 K、劳动 L 构造 -------- *
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

* -------- 1.3 企业所有制分类 firmcat -------- *
gen firmcat = . 
replace firmcat = 1 if firmtype == 1                  // 国企
replace firmcat = 2 if inlist(firmtype, 2, 3, 4)      // 外企
replace firmcat = 3 if missing(firmcat)               // 其他视为私企

label define firmcatlbl 1 "国企" 2 "外企" 3 "私企", replace
label values firmcat firmcatlbl

tab firmcat, gen(firmcat_)  // firmcat_1, firmcat_2, firmcat_3

* -------- 1.4 处理 firmtotalq / X（总中间投入） -------- *
confirm variable firmtotalq
if !_rc rename firmtotalq X

* -------- 1.5 重建资本存量（Brandt-Rawski deflator） -------- *
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

* -------- 1.6 其他成本变量与 log 变换 -------- *
rename 工业中间投入合计千元 MI
rename 管理费用千元 Mana

gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0

capture ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen double lratiofs = lnR - lnM   // 作为第一阶段被解释变量 r

gen ratio = importint/(domesticint+importint)

gen inputp  = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF      = importint/einputp

replace 开业成立时间年 = . if 开业成立时间年==0
gen age   = year - 开业成立时间年 + 1
gen lnage = ln(age)
gen lnmana = ln(Mana)

gen l   = ln(L)
gen lsq = l*l 
gen double k   = ln(K)
gen ksq = k*k  
gen double q   = ln(Q)
gen m = ln(delfateddomestic)        
gen double x   = ln(X)
gen double r   = ln(R)

gen DWL = WL/L
gen wl  = ln(DWL)

winsor2 k, cuts(1 99) by(cic2 year) replace
winsor2 l, cuts(1 99) by(cic2 year) replace
xtset firmid year

capture confirm variable pft
if !_rc rename pft pi
capture confirm variable foreignprice
if !_rc rename foreignprice WX
capture confirm variable WX
if !_rc gen double wx = ln(WX)

* -------- 1.7 第一阶段：估计成本 share vs. 生产要素（生成 es, es2q） -------- *
reg lratiofs k l wl x age lnmana i.firmcat i.city i.year, vce(cluster firmid)
predict double r_hat_ols, xb
gen double es   = exp(-r_hat_ols)
gen double es2q = es^2
* V1: keep first-stage fitted index for structural S-constraint linkage in second stage.
gen double shat = r_hat_ols

* -------- 1.8 第一阶段：估计 φ 的三次多项式（生成 phi, epsilon） -------- *
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmcat i.city i.year

predict double phi      if e(sample), xb
predict double epsilon  if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"

save "$DATA_WORK/firststage_`GROUPNAME'.dta", replace

*======================================================
* 模块 2：面板截取 & 滞后项、交互项构造
*   对应你原来"删选连续>= 2的公司"到各类 lag & interaction
*======================================================

* ---- 按 firmid-year 排序并保证唯一 ---- *
sort firmid year
isid firmid year, sort
di "✅ Data sorted and verified: unique firm-year combinations"

* ---- 2.1 只保留最长连续段 >=2年的公司 ---- *
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

* ---- 2.2 生成滞后项（phi, l, k, m, x 等） ---- *
isid firmid year, sort
xtset firmid year

gen double phi_lag = L.phi

gen double klag   = L.k
gen double mlag   = L.m
gen double xlag   = L.x
gen double llag   = L.l
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

gen double llag2  = L2.l
gen double llagk  = llag*k
gen double mlagl  = mlag*l
gen double mlagxlagk = mlagxlag*k
gen double xlagk  = xlag*k
gen double mlagk  = mlag*k
gen double mlagllag = mlag*llag
gen double llagxlagmlag = llagxlag*mlag
gen double xlagllag = xlag*llag
gen double xllagl  = xlag*l

gen double lages   = L.es
gen double lages2q = L.es2q
gen double klages  = k*lages
gen double shat_lag = L.shat

gen double kl      = k*l

capture confirm variable const
if _rc gen byte const = 1

order firmid year, first

*======================================================
* 模块 3：工具变量 Z & 控制变量 CONSOL 构造
*   对应你原先的 rangestat + merge IV + 年份虚拟 + drop if missing
*======================================================

* -------- 3.1 行业-年度同业均值（排除自身） -------- *
gen temp_l = l
gen temp_k = k
gen temp_m = m

capture ssc install rangestat, replace

rangestat (mean) temp_l, by(cic2 year) interval(firmid . .) excludeself
rename temp_l_mean l_ind_yr

rangestat (mean) temp_k, by(cic2 year) interval(firmid . .) excludeself
rename temp_k_mean k_ind_yr

rangestat (mean) temp_m, by(cic2 year) interval(firmid . .) excludeself
rename temp_m_mean m_ind_yr

drop temp_*

* -------- 3.2 合并关税 & HHI 工具变量 -------- *
merge m:1 firmid year using "$DATA_RAW/firm_year_IVs_Ztariff_ZHHI.dta"
keep if _merge==3
drop _merge
drop if missing(Z_tariff, Z_HHI_post)

* -------- 3.3 年份虚拟（以样本首年为基准） -------- *
levelsof year, local(yrs)
local base : word 1 of `yrs'
quietly tab year, gen(Dy)
local j = 1
foreach y of local yrs {
    if `y' == `base' drop Dy`j'
    else               rename Dy`j' dy`y'
    local ++j
}

xtset firmid year

* ---- 3.4 滞后年龄 lnagelag（用于控制） ---- *
capture confirm variable lnagelag
if _rc {
    gen double lnagelag = L.lnage
    di "✅ Created: lnagelag (lagged firm age)"
}

* ---- 3.5 最终样本筛选：保证所有 GMM 所需变量不缺失 ---- *
drop if missing(const, r, l, k, phi, phi_lag, llag, klag, mlag, lsqlag, ksqlag, ///
    lsq, ksq, m, es, es2q, lages, lages2q, shat, shat_lag, lnage, firmcat, lnmana, ///
    lnagelag, firmcat_2, firmcat_3, dy2002-dy2007, klages, mlagxlag)

* ---- 3.6 为 Mata 创建残差占位列 OMEGA2/XI2 ---- *
capture drop OMEGA2 XI2
gen double OMEGA2 = .
gen double XI2    = .

* ---- 3.7 have_b0 起点标志初始化（Stata 本地宏 + Mata local） ---- *
local have_b0 0
mata: st_local("have_b0", "`have_b0'")

*======================================================
* 模块 4：Mata 两步 GMM 引擎
*   对应你原来的整段 mata: 到 end
*   内部算法不改，只保留你现有的数值处理和防护。
*   （为了节省篇幅，这里直接沿用你当前版本的 Mata 代码）
*======================================================
mata:
mata clear

real scalar scalarmax(real scalar a, real scalar b)
{
    return( a > b ? a : b )
}

/* 初始化全局矩阵（用于 st_store 回写时保证存在） */
OMEGA2 = J(0,1,.)
XI2    = J(0,1,.)
AMC_LB = .
AMC_PAD = 1e-6

void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init, Wg_opt, AMC_LB, AMC_PAD
    external LVAR, KVAR, LSQVAR, KSQVAR, MVAR, LLAGVAR, KLAGVAR, LSQLAGVAR, KSQLAGVAR, MLAGVAR, SHAT, SHAT_lag

    /* V1 linked-constraint setup: X only for initialization; S is updated inside evaluator */
    X       = st_data(., ("const","l","k","lsq","ksq","m"))
    X_lag   = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag"))

    LVAR    = st_data(., "l")
    KVAR    = st_data(., "k")
    LSQVAR  = st_data(., "lsq")
    KSQVAR  = st_data(., "ksq")
    MVAR    = st_data(., "m")
    LLAGVAR   = st_data(., "llag")
    KLAGVAR   = st_data(., "klag")
    LSQLAGVAR = st_data(., "lsqlag")
    KSQLAGVAR = st_data(., "ksqlag")
    MLAGVAR   = st_data(., "mlag")
    SHAT      = st_data(., "shat")
    SHAT_lag  = st_data(., "shat_lag")

    /* IV sets by group and IV_SET switch */
    string scalar g, ivset, zov
    string rowvector zvars
    real scalar robust_mode
    g = st_global("GROUP_NAME")
    ivset = st_global("IV_SET")
    robust_mode = strtoreal(st_global("ROBUST_INIT"))
    if (ivset=="") ivset = "A"
    if (g!="G1_17_19" & g!="G2_39_41") {
        errprintf("Invalid GROUPNAME = [%s]; must be G1_17_19 or G2_39_41\n", g)
        _error(3499)
    }
    if (ivset!="A" & ivset!="B" & ivset!="C" & ivset!="A1" & ivset!="A2" & ivset!="A3") {
        errprintf("Invalid IV_SET = [%s]; must be A/B/C/A1/A2/A3\n", ivset)
        _error(3499)
    }

    zov = (g=="G1_17_19" ? st_global("IV_Z_G1") : st_global("IV_Z_G2"))
    if (zov!="") {
        zvars = tokens(zov)
        Z = st_data(., zvars)
    }
    else if (g=="G1_17_19" & ivset=="A") {
        Z = st_data(., ("const","lages2q","l","ksq","llag","klag","mlag","l_ind_yr","m_ind_yr","k_ind_yr","Z_HHI_post"))
    }
    else if (g=="G1_17_19" & ivset=="B") {
        Z = st_data(., ("const","lages2q","l","lsq","ksq","llag","klag","mlag","l_ind_yr","m_ind_yr","k_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G1_17_19" & ivset=="C") {
        Z = st_data(., ("const","llag","klag","mlag","lages","lages2q","l_ind_yr","m_ind_yr","k_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G2_39_41" & ivset=="A") {
        Z = st_data(., ("llag","klag","l","lages","lsq","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G2_39_41" & ivset=="B") {
        Z = st_data(., ("const","llag","klag","mlag","l","lsq","ksq","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G1_17_19" & ivset=="A1") {
        Z = st_data(., ("llag","klag","mlag","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","lages2q","lages"))
    }
    else if (g=="G1_17_19" & ivset=="A2") {
        Z = st_data(., ("llag","klag","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","lages2q","lages","klages"))
    }
    else if (g=="G1_17_19" & ivset=="A3") {
        Z = st_data(., ("llag","klag","k_ind_yr","m_ind_yr","Z_tariff","lages2q","lages","klages","llag2"))
    }
    else if (g=="G2_39_41" & ivset=="A1") {
        Z = st_data(., ("llag","mlag","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","Z_HHI_post","lages2q","lages"))
    }
    else if (g=="G2_39_41" & ivset=="A2") {
        Z = st_data(., ("llag","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","Z_HHI_post","lages2q","lages","llag2"))
    }
    else if (g=="G2_39_41" & ivset=="A3") {
        Z = st_data(., ("llag","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","lages2q","lages","llag2","klages"))
    }
    else {
        Z = st_data(., ("const","llag","klag","mlag","lages","lages2q","l_ind_yr","k_ind_yr","m_ind_yr","Z_HHI_post"))
    }

    PHI     = st_data(., "phi")
    PHI_lag = st_data(., "phi_lag")
    Y       = st_data(., "r")
    C       = st_data(., "const")

    CONSOL  = st_data(., ("dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","lnage","firmcat_2","firmcat_3"))

    real scalar use_b0, shbar, amc0, raw_amc0, lb_local
    real rowvector bols
    use_b0 = strtoreal(st_local("have_b0"))

    if (rows(X) != rows(Y)) {
        errprintf(">>> ERROR: rows(X) != rows(Y) in qrsolve\n")
        _error(3497)
    }
    if (cols(Y) != 1) {
        errprintf(">>> ERROR: Y is not a column vector in qrsolve\n")
        _error(3497)
    }
    if (any(missing(X)) | any(missing(Y)) | any(missing(SHAT)) | any(missing(SHAT_lag))) {
        errprintf(">>> ERROR: Missing values in core data before optimization\n")
        _error(3497)
    }

    /* Hard-linked S-constraint support:
       S=1-exp(-shat)/amc in (0,1) requires amc > exp(-shat), same for lag.
       Build a sample-specific lower bound and enforce it via reparameterization. */
    lb_local = max( (exp(-SHAT) \ exp(-SHAT_lag)) )
    if (missing(lb_local) | lb_local<=1e-8) {
        errprintf(">>> ERROR: invalid AMC lower bound from shat/shat_lag\n")
        _error(3497)
    }
    AMC_LB = lb_local
    st_numscalar("amc_lb", AMC_LB)
    st_numscalar("amc_pad", AMC_PAD)

    bols = qrsolve(X, Y)'
    shbar = mean(SHAT)
    if (missing(shbar)) shbar = 0
    amc0 = exp(-shbar) + 0.10
    if (amc0 <= AMC_LB*(1+AMC_PAD)) amc0 = AMC_LB*(1+100*AMC_PAD)
    raw_amc0 = ln( scalarmax(amc0 - AMC_LB*(1+AMC_PAD), 1e-8) )
    if (robust_mode==1 & (ivset=="A2" | ivset=="A3")) {
        amc0 = scalarmax(amc0, AMC_LB*(1+300*AMC_PAD))
        raw_amc0 = ln( scalarmax(amc0 - AMC_LB*(1+AMC_PAD), 1e-6) )
    }

    if (use_b0 == 1) {
        beta_init = st_matrix("b0")'
        if (cols(beta_init) != 8) {
            beta_init = (bols, raw_amc0, 0)
        }
        else if (robust_mode==1 & (ivset=="A2" | ivset=="A3") & beta_init[7] < raw_amc0) {
            beta_init[7] = raw_amc0
        }
    }
    else {
        beta_init = (bols, raw_amc0, 0)
    }
}

void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, Z, C, CONSOL, Wg, Wg_opt, AMC_LB, AMC_PAD
    external LVAR, KVAR, LSQVAR, KSQVAR, MVAR, LLAGVAR, KLAGVAR, LSQLAGVAR, KSQLAGVAR, MLAGVAR, SHAT, SHAT_lag

    real colvector OMEGA, OMEGA_lag, XI, gb, m, S_now, S_lag
    real matrix POOL
    real scalar N, crit_val, amc, smin_now, smax_now, smin_lag, smax_lag

    N = rows(Z)
    if (N <= 5 | any(missing(Z))) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    if (rows(Wg_opt)==0 | cols(Wg_opt)==0 | rows(Wg_opt)!=cols(Z) | cols(Wg_opt)!=cols(Z)) {
        Wg_opt = I(cols(Z))
    }

    /* Hard-linked S-constraint reparameterization:
       amc = AMC_LB*(1+AMC_PAD) + exp(raw_amc), so amc always stays in feasible region. */
    amc = AMC_LB*(1+AMC_PAD) + exp(b[7])
    if (missing(amc) | amc<=AMC_LB*(1+AMC_PAD) | amc>1e+12) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    S_now = 1 :- exp(-SHAT) :/ amc
    S_lag = 1 :- exp(-SHAT_lag) :/ amc
    smin_now = min(S_now); smax_now = max(S_now)
    smin_lag = min(S_lag); smax_lag = max(S_lag)
    if (any(missing(S_now)) | any(missing(S_lag)) | smin_now<=1e-8 | smax_now>=1-1e-8 | smin_lag<=1e-8 | smax_lag>=1-1e-8) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    OMEGA = PHI :- (b[1] :+ b[2]:*LVAR :+ b[3]:*KVAR :+ b[4]:*LSQVAR :+ b[5]:*KSQVAR :+ b[6]:*MVAR :+ b[8]:*(S_now:^2))
    OMEGA_lag = PHI_lag :- (b[1] :+ b[2]:*LLAGVAR :+ b[3]:*KLAGVAR :+ b[4]:*LSQLAGVAR :+ b[5]:*KSQLAGVAR :+ b[6]:*MLAGVAR :+ b[8]:*(S_lag:^2))

    if (cols(CONSOL)>0) POOL = (C, OMEGA_lag, CONSOL)
    else                POOL = (C, OMEGA_lag)

    gb  = qrsolve(POOL, OMEGA)
    XI  = OMEGA - POOL * gb

    N       = rows(Z)
    m       = quadcross(Z, XI) :/ N
    crit_val = m' * Wg_opt * m

    if (missing(crit_val) | crit_val>1e+30 | crit_val<-1e+30) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    if (crit_val < 1e-10 * N) {
        crit = crit_val
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    crit = crit_val

    if (todo>=1) {
        real scalar i, eps_i, crit_plus, crit_minus
        real rowvector gnum, btmp
        real colvector Oe, Oel, XI2p, XI2m, m2p, m2m, Sp, Slp, Sm, Slm
        real matrix PO

        gnum = J(1, cols(b), .)

        for (i=1; i<=cols(b); i++) {
            eps_i = scalarmax(1e-6, 1e-6 * abs(b[i]))

            btmp    = b
            btmp[i] = b[i] + eps_i
            amc = AMC_LB*(1+AMC_PAD) + exp(btmp[7])
            if (missing(amc) | amc<=AMC_LB*(1+AMC_PAD) | amc>1e+12) {
                crit_plus = 1e+20
            }
            else {
                Sp = 1 :- exp(-SHAT) :/ amc
                Slp = 1 :- exp(-SHAT_lag) :/ amc
                if (any(missing(Sp)) | any(missing(Slp)) | min(Sp)<=1e-8 | max(Sp)>=1-1e-8 | min(Slp)<=1e-8 | max(Slp)>=1-1e-8) {
                    crit_plus = 1e+20
                }
                else {
                    Oe = PHI :- (btmp[1] :+ btmp[2]:*LVAR :+ btmp[3]:*KVAR :+ btmp[4]:*LSQVAR :+ btmp[5]:*KSQVAR :+ btmp[6]:*MVAR :+ btmp[8]:*(Sp:^2))
                    Oel = PHI_lag :- (btmp[1] :+ btmp[2]:*LLAGVAR :+ btmp[3]:*KLAGVAR :+ btmp[4]:*LSQLAGVAR :+ btmp[5]:*KSQLAGVAR :+ btmp[6]:*MLAGVAR :+ btmp[8]:*(Slp:^2))
                    PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
                    gb  = qrsolve(PO, Oe)
                    XI2p = Oe - PO*gb
                    m2p  = quadcross(Z, XI2p):/ N
                    crit_plus = m2p' * Wg_opt * m2p
                }
            }

            btmp    = b
            btmp[i] = b[i] - eps_i
            amc = AMC_LB*(1+AMC_PAD) + exp(btmp[7])
            if (missing(amc) | amc<=AMC_LB*(1+AMC_PAD) | amc>1e+12) {
                crit_minus = 1e+20
            }
            else {
                Sm = 1 :- exp(-SHAT) :/ amc
                Slm = 1 :- exp(-SHAT_lag) :/ amc
                if (any(missing(Sm)) | any(missing(Slm)) | min(Sm)<=1e-8 | max(Sm)>=1-1e-8 | min(Slm)<=1e-8 | max(Slm)>=1-1e-8) {
                    crit_minus = 1e+20
                }
                else {
                    Oe = PHI :- (btmp[1] :+ btmp[2]:*LVAR :+ btmp[3]:*KVAR :+ btmp[4]:*LSQVAR :+ btmp[5]:*KSQVAR :+ btmp[6]:*MVAR :+ btmp[8]:*(Sm:^2))
                    Oel = PHI_lag :- (btmp[1] :+ btmp[2]:*LLAGVAR :+ btmp[3]:*KLAGVAR :+ btmp[4]:*LSQLAGVAR :+ btmp[5]:*KSQLAGVAR :+ btmp[6]:*MLAGVAR :+ btmp[8]:*(Slm:^2))
                    PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
                    gb  = qrsolve(PO, Oe)
                    XI2m = Oe - PO*gb
                    m2m  = quadcross(Z, XI2m):/ N
                    crit_minus = m2m' * Wg_opt * m2m
                }
            }

            if (missing(crit_plus) | missing(crit_minus)) {
                gnum[i] = 0
            }
            else {
                gnum[i] = (crit_plus - crit_minus) / (2*eps_i)
            }
        }

        g = gnum
    }
}

void run_two_step()
{
    st_numscalar("gmm_conv1", 0)
    st_numscalar("gmm_conv2", 0)
    st_numscalar("gmm_conv",  0)
    st_numscalar("J_unit",    .)
    st_numscalar("J_opt",     .)
    st_numscalar("J_df",      .)
    st_numscalar("J_p",       .)

    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL, Wg, beta_init, Wg_opt, AMC_LB, AMC_PAD
    external LVAR, KVAR, LSQVAR, KSQVAR, MVAR, LLAGVAR, KLAGVAR, LSQLAGVAR, KSQLAGVAR, MLAGVAR, SHAT, SHAT_lag

    real scalar Kz, Kx, J1, J2, lam, conv1, conv2, smin, smax, cond, EPSJ, robust_mode
    string scalar ivset
    real rowvector b1, b2
    real colvector OMEGA1, OMEGA1_lag, XI1, OMEGA2_local, OMEGA2_lag, XI2_local, g_bvec, m_unit, m_opt
    real colvector S1_now, S1_lag, S2_now, S2_lag
    real colvector svals
    real matrix POOL1, Mrow, S, POOL2, Wloc
    real scalar N, Junit, Jopt, df, jp, amc1, amc2
    real scalar conv2_nr, J2_nr
    real rowvector b2_nr

    N = rows(Z)
    ivset = st_global("IV_SET")
    robust_mode = strtoreal(st_global("ROBUST_INIT"))
    st_numscalar("Nobs", N)

    Kz = cols(Z)
    Kx = cols(beta_init)
    st_numscalar("Kz_used", Kz)
    if (Kz < Kx) {
        errprintf("ERROR: Not enough instruments (Kz=%f < Kx=%f).\n", Kz, Kx)
        _error(3498)
    }

    Wg_opt = I(Kz)

    real scalar S1
    S1 = optimize_init()
    optimize_init_evaluator(S1, &GMM_DL_weighted())
    optimize_init_evaluatortype(S1, "d0")
    optimize_init_which(S1, "min")
    optimize_init_params(S1, beta_init)
    optimize_init_technique(S1, "nm")
    if (robust_mode==1 & (ivset=="A2" | ivset=="A3")) {
        optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.002))
        optimize_init_conv_maxiter(S1, 4000)
    }
    else {
        optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.01))
        optimize_init_conv_maxiter(S1, 2000)
    }
    optimize_init_conv_ptol(S1, 1e-8)
    optimize_init_conv_vtol(S1, 1e-8)
    optimize_init_tracelevel(S1, "none")

    b1    = J(1, Kx, .)
    b1    = optimize(S1)
    J1    = optimize_result_value(S1)
    conv1 = optimize_result_converged(S1)
    st_numscalar("gmm_conv1", conv1)

    if (!conv1) {
        optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.01))
        optimize_init_params(S1, b1)
        b1    = optimize(S1)
        J1    = optimize_result_value(S1)
        conv1 = optimize_result_converged(S1)
        st_numscalar("gmm_conv1", conv1)
    }

    amc1 = AMC_LB*(1+AMC_PAD) + exp(b1[7])
    if (missing(amc1) | amc1<=AMC_LB*(1+AMC_PAD) | amc1>1e+12) {
        errprintf("ERROR: invalid amc in step 1.\n")
        _error(3498)
    }
    S1_now = 1 :- exp(-SHAT) :/ amc1
    S1_lag = 1 :- exp(-SHAT_lag) :/ amc1
    if (min(S1_now)<=1e-8 | max(S1_now)>=1-1e-8 | min(S1_lag)<=1e-8 | max(S1_lag)>=1-1e-8) {
        errprintf("ERROR: S outside (0,1) in step 1.\n")
        _error(3498)
    }
    OMEGA1 = PHI :- (b1[1] :+ b1[2]:*LVAR :+ b1[3]:*KVAR :+ b1[4]:*LSQVAR :+ b1[5]:*KSQVAR :+ b1[6]:*MVAR :+ b1[8]:*(S1_now:^2))
    OMEGA1_lag = PHI_lag :- (b1[1] :+ b1[2]:*LLAGVAR :+ b1[3]:*KLAGVAR :+ b1[4]:*LSQLAGVAR :+ b1[5]:*KSQLAGVAR :+ b1[6]:*MLAGVAR :+ b1[8]:*(S1_lag:^2))
    // First-step linked-constraint transition.
    if (cols(CONSOL)>0) POOL1 = (C, OMEGA1_lag, CONSOL)
    else                POOL1 = (C, OMEGA1_lag)
    XI1  = OMEGA1 - POOL1 * qrsolve(POOL1, OMEGA1)
    Mrow = Z :* (XI1 * J(1, cols(Z), 1))
    S    = (Mrow' * Mrow) :/ N

    svals = svdsv(S)
    smin  = min(svals)
    smax  = max(svals)
    cond  = smax / scalarmax(smin, 1e-12)

    lam = 0
    if (cond > 1e6) {
        lam = scalarmax(1e-4, (1e-6 * smax))
    }

    if (lam > 0) Wloc = invsym(S + lam * I(Kz))
    else         Wloc = invsym(S)

    Wg_opt = Wloc
    st_matrix("W_opt", Wg_opt)

    real scalar S2
    EPSJ = 1e-8 * N
    S2 = optimize_init()
    optimize_init_evaluator(S2, &GMM_DL_weighted())
    optimize_init_evaluatortype(S2, "d0")
    optimize_init_which(S2, "min")
    optimize_init_params(S2, b1)
    optimize_init_technique(S2, "nm")
    if (robust_mode==1 & (ivset=="A2" | ivset=="A3")) {
        optimize_init_nmsimplexdeltas(S2, J(1, cols(b1), 0.0002))
        optimize_init_conv_maxiter(S2, 5000)
    }
    else {
        optimize_init_nmsimplexdeltas(S2, J(1, cols(b1), 0.00001))
        optimize_init_conv_maxiter(S2, 3000)
    }
    optimize_init_conv_ptol(S2, 1e-8)
    optimize_init_conv_vtol(S2, 1e-8)
    optimize_init_tracelevel(S2, "none")

    b2    = J(1, Kx, .)
    b2    = optimize(S2)
    J2    = optimize_result_value(S2)
    conv2 = optimize_result_converged(S2)

    if (!conv2) {
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
    }

    if (robust_mode==1 & (ivset=="A2" | ivset=="A3") & (!conv2 | J2 > EPSJ)) {
        real matrix starts
        real scalar r
        real rowvector b_try
        starts = (b1 \ (b1:+(0,0,0,0,0,0,0.4,0)) \ (b1:+(0,0,0,0,0,0,0.8,0)) \ (b1:+(0,0,0,0,0,0,0.4,0.1)))
        for (r=1; r<=rows(starts); r++) {
            S2 = optimize_init()
            optimize_init_evaluator(S2, &GMM_DL_weighted())
            optimize_init_evaluatortype(S2, "d0")
            optimize_init_which(S2, "min")
            b_try = starts[r,.]
            optimize_init_params(S2, b_try)
            optimize_init_technique(S2, "nm")
            optimize_init_nmsimplexdeltas(S2, J(1, cols(b_try), 0.0002))
            optimize_init_conv_maxiter(S2, 5000)
            optimize_init_conv_ptol(S2, 1e-9)
            optimize_init_conv_vtol(S2, 1e-9)
            optimize_init_tracelevel(S2, "none")
            b2    = optimize(S2)
            J2_nr = optimize_result_value(S2)
            conv2_nr = optimize_result_converged(S2)
            if (conv2_nr & (J2_nr <= J2 | !conv2)) {
                J2 = J2_nr
                conv2 = conv2_nr
            }
        }
    }

    if (( !conv2 | J2 > EPSJ ) & rows(b2)==1 & cols(b2)==Kx) {
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
        }
    }

    st_numscalar("gmm_conv2", conv2)

    amc2 = AMC_LB*(1+AMC_PAD) + exp(b2[7])
    if (missing(amc2) | amc2<=AMC_LB*(1+AMC_PAD) | amc2>1e+12) {
        errprintf("ERROR: invalid amc in step 2.\n")
        _error(3498)
    }
    S2_now = 1 :- exp(-SHAT) :/ amc2
    S2_lag = 1 :- exp(-SHAT_lag) :/ amc2
    if (min(S2_now)<=1e-8 | max(S2_now)>=1-1e-8 | min(S2_lag)<=1e-8 | max(S2_lag)>=1-1e-8) {
        errprintf("ERROR: S outside (0,1) in step 2.\n")
        _error(3498)
    }
    OMEGA2_local = PHI :- (b2[1] :+ b2[2]:*LVAR :+ b2[3]:*KVAR :+ b2[4]:*LSQVAR :+ b2[5]:*KSQVAR :+ b2[6]:*MVAR :+ b2[8]:*(S2_now:^2))
    OMEGA2_lag = PHI_lag :- (b2[1] :+ b2[2]:*LLAGVAR :+ b2[3]:*KLAGVAR :+ b2[4]:*LSQLAGVAR :+ b2[5]:*KSQLAGVAR :+ b2[6]:*MLAGVAR :+ b2[8]:*(S2_lag:^2))
    // Second-step linked-constraint transition.

    if (cols(CONSOL)>0) POOL2 = (C, OMEGA2_lag, CONSOL)
    else                POOL2 = (C, OMEGA2_lag)

    g_bvec    = qrsolve(POOL2, OMEGA2_local)
    XI2_local = OMEGA2_local - POOL2 * g_bvec

    m_unit = quadcross(Z, XI2_local) :/ N
    m_opt  = quadcross(Z, XI2_local) :/ N

    Junit = N * quadcross(m_unit, m_unit)
    Jopt  = N * quadcross(m_opt, Wg_opt * m_opt)

    df = Kz - Kx
    jp = .
    if (df > 0 & Jopt >= 0) jp = chi2tail(df, Jopt)

    st_matrix("beta_lin_step1", b1')
    st_matrix("beta_lin",       b2')
    st_matrix("g_b",            g_bvec)
    st_matrix("moments_unit",   m_unit')
    st_matrix("moments_opt",    m_opt')
    st_matrix("W_opt",          Wg_opt)

    st_numscalar("J_unit",   Junit)
    st_numscalar("J_opt",    Jopt)
    st_numscalar("J_df",     df)
    st_numscalar("J_p",      jp)
    st_numscalar("gmm_conv", (conv1 & conv2))

    real scalar nobs
    nobs = st_nobs()
    if (rows(OMEGA2_local) == nobs) st_store(., "OMEGA2", OMEGA2_local)
    if (rows(XI2_local)    == nobs) st_store(., "XI2",    XI2_local)
}

end

*======================================================
* 模块 5：Stata 包装程序 + 全样本点估（不含诊断）
*   对应你原来 gmm2step_once + "全样本先跑一次"
*======================================================

capture program drop gmm2step_once
program define gmm2step_once, rclass
    version 18
    syntax [, rep(integer 0)]
    
    timer clear 1
    timer on 1
    
    mata: mata set matastrict on
    mata: refresh_globals()
    mata: run_two_step()
    local rc_mata = _rc

    if `rc_mata' == 111 {
        capture confirm scalar J_opt
        if _rc == 0 {
            di as txt "NOTE: run_two_step() returned rc=111 (simplex warning), but J_opt is available. Proceeding."
            local rc_mata = 0
        }
    }
    if `rc_mata' {
        di as err "ERROR in run_two_step(): rc=`rc_mata'"
        exit `rc_mata'
    }
    
    confirm scalar gmm_conv
    if _rc {
        di as err "gmm_conv not returned"
        exit 498
    }
    if scalar(gmm_conv) != 1 {
        di as txt "WARNING: GMM did not fully converge (gmm_conv=`=scalar(gmm_conv)')"
    }
    
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
    * V1 linked-constraint parameters:
    * raw b[7] maps to amc = amc_lb*(1+amc_pad) + exp(raw_amc), enforcing S-feasible support.
    return scalar b_amc  = scalar(amc_lb)*(1+scalar(amc_pad)) + exp(b[7,1])
    return scalar b_as   = b[8,1]
    * Backward-compatible aliases (kept to avoid breaking master aggregation code).
    return scalar b_es   = scalar(amc_lb)*(1+scalar(amc_pad)) + exp(b[7,1])
    return scalar b_essq = b[8,1]
    
    confirm matrix g_b
    if _rc {
        di as err "g_b not returned"
        exit 498
    }
    matrix gb = g_b
    capture matrix rownames gb = c0_omega ar1_omega dy2002 dy2003 dy2004 dy2005 dy2006 dy2007 lnage firmcat_2 firmcat_3
    return scalar b_c0_omega  = gb[1,1]
    return scalar b_ar1_omega = gb[2,1]
    return scalar b_lnage     = gb[9,1]
    return scalar b_firmcat_2 = gb[10,1]
    return scalar b_firmcat_3 = gb[11,1]
    
    return scalar J_unit = scalar(J_unit)
    confirm scalar J_opt
    if !_rc return scalar J_opt = scalar(J_opt)
    confirm scalar J_p
    if !_rc return scalar J_p = scalar(J_p)
    
    timer off 1
    timer list 1
    return scalar time = r(t1)
    
    di as txt "Rep `rep': completed in `=r(t1)' sec. J_opt=`=scalar(J_opt)'"
end

* -------- 5.1 全样本 GMM（获取 b0 和点估） -------- *
local have_b0 0
mata: st_local("have_b0","`have_b0'")

di as text _n(2) "{hline 80}"
di as text "Running full-sample GMM to get starting values and point estimates"
di as text "{hline 80}"

noisily gmm2step_once
local rc = _rc

if (`rc'==430) {
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
        local have_b0 1
        mata: st_local("have_b0","`have_b0'")
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

* ---- 5.2 抓取控制变量系数，用于写入点估文件 ---- *
local b_const_hat = r(b_c1)
local b_l_hat     = r(b_l)
local b_k_hat     = r(b_k)
local b_lsq_hat   = r(b_lsq)
local b_ksq_hat   = r(b_ksq)
local b_m_hat     = r(b_m)
local b_amc_hat   = r(b_amc)
local b_as_hat    = r(b_as)
local b_c0_omega_hat  = r(b_c0_omega)
local b_ar1_omega_hat = r(b_ar1_omega)
local b_lnage_hat    = r(b_lnage)
local b_firmcat2_hat = r(b_firmcat_2)
local b_firmcat3_hat = r(b_firmcat_3)
di as txt "Main spec dynamic block (AR(1)-style): c0=" %9.5f `b_c0_omega_hat' "  rho=" %9.5f `b_ar1_omega_hat'

* ---- 5.3 Elasticity diagnostics from point estimates ---- *
capture drop theta_k_hat theta_l_hat theta_m_hat
gen double theta_k_hat = `b_k_hat' + 2*`b_ksq_hat'*k
gen double theta_l_hat = `b_l_hat' + 2*`b_lsq_hat'*l
gen double theta_m_hat = `b_m_hat'

qui summarize theta_k_hat, meanonly
local elas_k_mean = r(mean)
qui summarize theta_l_hat, meanonly
local elas_l_mean = r(mean)
qui summarize theta_m_hat, meanonly
local elas_m_mean = r(mean)

qui count
local N_elas = r(N)
qui count if theta_k_hat < 0
local elas_k_negshare = cond(`N_elas'>0, r(N)/`N_elas', .)
qui count if theta_l_hat < 0
local elas_l_negshare = cond(`N_elas'>0, r(N)/`N_elas', .)
qui count if theta_m_hat < 0
local elas_m_negshare = cond(`N_elas'>0, r(N)/`N_elas', .)

di as txt "Elasticity means: theta_K=" %9.5f `elas_k_mean' "  theta_L=" %9.5f `elas_l_mean' "  theta_M=" %9.5f `elas_m_mean'
di as txt "Elasticity negative shares: theta_K=" %6.3f `elas_k_negshare' "  theta_L=" %6.3f `elas_l_negshare' "  theta_M=" %6.3f `elas_m_negshare'

preserve
    keep firmid year cic2 theta_k_hat theta_l_hat theta_m_hat
    gen str10 group = "`GROUPNAME'"
    order group firmid year cic2 theta_k_hat theta_l_hat theta_m_hat
    compress
    save "$DATA_WORK/elasticity_group_`GROUPNAME'.dta", replace
restore

* ---- 5.4 firm-level omega_hat / xi_hat output ---- *
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
    save "$DATA_WORK/omega_xi_group_`GROUPNAME'.dta", replace
restore

* ---- 5.4 保存全样本点估（不含 bootstrap se） ---- *
quietly count
local Nobs = r(N)
preserve
    clear
    set obs 1
    gen group = "`GROUPNAME'"
    matrix b = beta_lin
    gen b_const = `b_const_hat'
    gen b_l     = `b_l_hat'
    gen b_k     = `b_k_hat'
    gen b_lsq   = `b_lsq_hat'
    gen b_ksq   = `b_ksq_hat'
    gen b_m     = `b_m_hat'
    gen b_amc   = `b_amc_hat'
    gen b_as    = `b_as_hat'
    * Backward-compatible aliases
    gen b_es    = b_amc
    gen b_essq  = b_as

    gen b_c0_omega  = `b_c0_omega_hat'
    gen b_ar1_omega = `b_ar1_omega_hat'
    gen b_lnage     = `b_lnage_hat'
    gen b_firmcat_2 = `b_firmcat2_hat'
    gen b_firmcat_3 = `b_firmcat3_hat'
    gen elas_k_mean = `elas_k_mean'
    gen elas_l_mean = `elas_l_mean'
    gen elas_m_mean = `elas_m_mean'
    gen elas_k_negshare = `elas_k_negshare'
    gen elas_l_negshare = `elas_l_negshare'
    gen elas_m_negshare = `elas_m_negshare'
    
    gen J_unit  = J_unit
    gen J_opt   = J_opt
    gen J_df    = J_df
    gen J_p     = J_p
    gen N       = `Nobs'
    if `RUN_BOOT'==0 {
        gen se_const = .
        gen se_l     = .
        gen se_k     = .
        gen se_lsq   = .
        gen se_ksq   = .
        gen se_m     = .
        gen se_es    = .
        gen se_essq  = .
        gen se_amc   = .
        gen se_as    = .
        gen se_c0_omega  = .
        gen se_ar1_omega = .
        gen se_lnage     = .
        gen se_firmcat_2 = .
        gen se_firmcat_3 = .
        gen se_J_unit    = .
        gen se_J_opt     = .
        gen boot_reps    = 0
        gen avg_time     = .
        order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq ///
              b_m se_m b_amc se_amc b_as se_as b_es se_es b_essq se_essq ///
              b_c0_omega se_c0_omega b_ar1_omega se_ar1_omega ///
              elas_k_mean elas_l_mean elas_m_mean elas_k_negshare elas_l_negshare elas_m_negshare ///
              b_lnage se_lnage b_firmcat_2 se_firmcat_2 b_firmcat_3 se_firmcat_3 ///
              J_unit se_J_unit J_opt se_J_opt J_df J_p N boot_reps avg_time
    }
    else {
        order group b_const b_l b_k b_lsq b_ksq b_m b_amc b_as b_es b_essq ///
              b_c0_omega b_ar1_omega b_lnage b_firmcat_2 b_firmcat_3 ///
              elas_k_mean elas_l_mean elas_m_mean elas_k_negshare elas_l_negshare elas_m_negshare ///
              J_unit J_opt J_df J_p N
    }
    compress
    save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace
restore

*======================================================
* 模块 6：可选诊断（线性 IV + J 分解打印）
*   只影响屏幕输出和附加诊断，不影响 GMM 点估与 bootstrap。
*======================================================

if `RUN_DIAG' {

    di as text _n(1) "---------- IV diagnostics (A/B/C sets) ----------"
    di as text "Current optimization IV_SET = `IV_SET'"

    capture ssc install ranktest, replace
    capture ssc install ivreg2,   replace

    local endog4 l k m

    if "`GROUPNAME'" == "G1_17_19" {
        * Excluded IVs: remove contemporaneous endogenous variable l.
        local z_A llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_post
        local z_B llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
        local z_C llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
    }
    else {
        local z_A llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_HHI_post
        local z_B llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
        * Excluded IVs: remove contemporaneous endogenous variable l.
        local z_C llag klag mlag l_ind_yr k_ind_yr m_ind_yr Z_tariff Z_HHI_post
    }

    tempname HDIAG
    tempfile ivdiag
    postfile `HDIAG' str4 iv_set byte ok double N jp jstat widstat str80 reason using "`ivdiag'", replace

    foreach S in A B C {
        * Safe macro expansion by branch to avoid malformed tokens like `l.
        local z_excl ""
        if "`S'"=="A" local z_excl "`z_A'"
        if "`S'"=="B" local z_excl "`z_B'"
        if "`S'"=="C" local z_excl "`z_C'"

        local miss 0
        local misslist ""
        foreach z of local z_excl {
            capture confirm variable `z'
            if _rc {
                local miss 1
                local misslist "`misslist' `z'"
            }
        }

        if `miss' {
            local misslist = trim("`misslist'")
            post `HDIAG' ("`S'") (0) (.) (.) (.) (.) ("missing: `misslist'")
            continue
        }

        capture noisily ivreg2 r const dy2002-dy2007 lnage firmcat_2 firmcat_3 ///
               (`endog4' = `z_excl') lsq ksq, ///
               nocons robust cluster(firmid) first

        local rc = _rc
        if (`rc'==0) {
            local N = e(N)
            local jp = .
            local jstat = .
            local widstat = .
            capture scalar __jp = e(jp)
            if !_rc local jp = scalar(__jp)
            capture scalar __j = e(j)
            if !_rc local jstat = scalar(__j)
            capture scalar __wid = e(widstat)
            if !_rc local widstat = scalar(__wid)

            post `HDIAG' ("`S'") (1) (`N') (`jp') (`jstat') (`widstat') ("ok")
        }
        else {
            post `HDIAG' ("`S'") (0) (.) (.) (.) (.) ("ivreg2 failed")
        }
    }
    postclose `HDIAG'

    preserve
        use "`ivdiag'", clear
        gen byte pass_j = (ok==1 & !missing(jp) & jp>=0.01 & jp<=0.99)
        order iv_set ok pass_j N jp jstat widstat reason
        compress
        save "$DATA_WORK/iv_diag_group_`GROUPNAME'.dta", replace
        di as text "Saved IV diagnostics: $DATA_WORK/iv_diag_group_`GROUPNAME'.dta"
        list, noobs
    restore

    matrix list beta_lin_step1
    matrix list beta_lin
    matrix list moments_unit
    matrix list moments_opt
    scalar list J_unit J_opt J_df J_p gmm_conv
}

*======================================================
* 模块 7：Bootstrap 循环 + bootstrap 标准误
*   对应你原来的 bootstrap 部分，逻辑不变。
*======================================================

if `RUN_BOOT' {
di as text _n(2) "{hline 80}"
di as text "Starting bootstrap estimation (clustered by firmid)"
di as text "{hline 80}"

tempname H
tempfile bootres
local failed = 0
local total_time = 0

set seed 20250830
local B = 2

tempfile failures
postfile failures rep reason using "`failures'", replace

    postfile `H' rep double(b_const b_l b_k b_lsq b_ksq b_m b_es b_essq ///
                      b_c0_omega b_ar1_omega b_lnage b_firmcat_2 b_firmcat_3 J_unit J_opt time) ///
    using "`bootres'", replace

forvalues ro = 1/`B' {
    di as text _n "Bootstrap rep `ro'/`B'"
    
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
        
        quietly gmm2step_once, rep(`ro')
        local rc = _rc
        
        if (`rc' == 0) {
            confirm scalar gmm_conv
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
            post `H' (`ro') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_lsq)) (r(b_ksq)) (r(b_m)) ///
                   (r(b_es)) (r(b_essq)) (r(b_c0_omega)) (r(b_ar1_omega)) (r(b_lnage)) (r(b_firmcat_2)) (r(b_firmcat_3)) ///
                   (r(J_unit)) (r(J_opt)) (r(time))
            
            confirm matrix beta_lin
            if (_rc == 0) {
                matrix b0 = beta_lin
                local have_b0 1
                mata: st_local("have_b0","`have_b0'")
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

use "`failures'", clear
if _N > 0 {
    list, noobs
    save "$DATA_WORK/bootstrap_failures_`GROUPNAME'.dta", replace
}

use "`bootres'", clear
if _N == 0 {
    di as err "No successful bootstrap replications. Cannot compute SEs."
    exit 430
}

* ---- 7.2 计算 bootstrap 标准误并追加到点估文件 ---- *
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
local se_amc   = `se_es'
local se_as    = `se_essq'
qui summarize b_c0_omega, detail
local se_c0_omega  = r(sd)
qui summarize b_ar1_omega, detail
local se_ar1_omega = r(sd)
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

use "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", clear
gen se_const = `se_const'
gen se_l     = `se_l'
gen se_k     = `se_k'
gen se_lsq   = `se_lsq'
gen se_ksq   = `se_ksq'
gen se_m     = `se_m'
gen se_es    = `se_es'
gen se_essq  = `se_essq'
gen se_amc   = `se_amc'
gen se_as    = `se_as'
gen se_c0_omega  = `se_c0_omega'
gen se_ar1_omega = `se_ar1_omega'
gen se_lnage     = `se_lnage'
gen se_firmcat_2 = `se_firmcat_2'
gen se_firmcat_3 = `se_firmcat_3'
gen se_J_unit    = `se_J_unit'
gen se_J_opt     = `se_J_opt'
gen boot_reps    = `=`B'-`failed''
gen avg_time     = `=`total_time'/(`B'-`failed')'

order group b_const se_const b_l se_l b_k se_k b_lsq se_lsq b_ksq se_ksq ///
      b_m se_m b_amc se_amc b_as se_as b_es se_es b_essq se_essq ///
      b_c0_omega se_c0_omega b_ar1_omega se_ar1_omega ///
      elas_k_mean elas_l_mean elas_m_mean elas_k_negshare elas_l_negshare elas_m_negshare ///
      b_lnage se_lnage b_firmcat_2 se_firmcat_2 b_firmcat_3 se_firmcat_3 ///
      J_unit se_J_unit J_opt se_J_opt J_df J_p N boot_reps avg_time

compress
save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace

use "`bootres'", clear
compress
save "$DATA_WORK/gmm_boot_group_`GROUPNAME'.dta", replace

di as res _n(2) "{hline 80}"
di as res "Done group `GROUPNAME'. Files written:"
di as res "  gmm_point_group_`GROUPNAME'.dta   (points + bootstrap SEs + diagnostics)"
di as res "  gmm_boot_group_`GROUPNAME'.dta    (draws)"
di as res "  omega_xi_group_`GROUPNAME'.dta   (firm-level residuals)"
di as res "  elasticity_group_`GROUPNAME'.dta (firm-level elasticities)"
if `failed' > 0 di as res "  bootstrap_failures_`GROUPNAME'.dta (failure reasons)"
di as res "{hline 80}"
}
else {
    di as text _n(2) "{hline 80}"
    di as text "RUN_POINT_ONLY mode: skip bootstrap and keep point estimates only"
    di as text "{hline 80}"
    di as text "Point-only placeholders already initialized in gmm_point_group_`GROUPNAME'.dta"
}

display as text "INFO: Script finished at " c(current_time)
