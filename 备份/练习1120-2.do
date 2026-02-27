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


// ===== 你的数据处理与构造部分=====
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
replace firmcat = 3 if missing(firmcat)

* 添加标签
label define firmcatlbl 1 "国企" 2 "外企" 3 "私企", replace
label values firmcat firmcatlbl
* -------- 2) 生成虚拟变量（基准：国企）--------
capture drop firmcat_*
tab firmcat, gen(firmcat_)

* 检查分类结果
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

winsor2 k, cuts(1 99) by(cic2 year) replace
winsor2 l, cuts(1 99) by(cic2 year) replace
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

* phi cubic 
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmcat i.city i.year
// 回归（你的第一阶段）后：预测后只对有效样本赋值
predict double phi if e(sample), xb
predict double epsilon if e(sample), residuals
assert !missing(phi, epsilon) if e(sample)
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"
save "firststage.dta", replace

**删选连续>= 2的公司，以及删除首年不保留（因为后面有lag）
* 1. 按公司ID和年份排序
sort firmid year

* 验证数据唯一性
isid firmid year, sort
di "✅ Data sorted and verified: unique firm-year combinations"

* 2. 计算年份间隔
by firmid: gen gap = year - L.year

* 3. 识别连续段
by firmid: gen seqblock = (gap != 1 | missing(gap))
by firmid: replace seqblock = sum(seqblock)

* 4. 计算每个连续段的长度
bys firmid seqblock: gen seg_len = _N

* 5. 计算每家公司的最长连续段长度
bys firmid: egen max_seg_len = max(seg_len)

* 6. 只保留最长连续段≥2年的公司（保留这些公司的所有观测）
keep if max_seg_len >= 2

* 7. 删除辅助变量
drop gap seqblock seg_len max_seg_len

* 8. 验证结果
bys firmid: gen nobs_firm = _N
tab nobs_firm, missing
sum nobs_firm, detail
drop nobs_firm

*生成滞后项

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
	
	* 先在 Stata 里创建占位变量，供 Mata 写入残差 ——1120添加 —— *
capture drop OMEGA2 XI2                 // 防止之前已有同名变量 ——1120添加 —— *
gen double OMEGA2 = .                   // 与样本行数相同的空列 ——1120添加 —— *
gen double XI2    = .                   // ——1120添加 —— *

*==================== Mata (two-step GMM; add tariff to CONSOL) ====================*

mata:
mata clear

// ===== 全局对象：用来在 refresh_globals() / run_one_step() 之间共享 =====
X        = J(0,0,.)
X_lag    = J(0,0,.)
Z        = J(0,0,.)
PHI      = J(0,1,.)
PHI_lag  = J(0,1,.)
Y        = J(0,1,.)
C        = J(0,1,.)
CONSOL   = J(0,0,.)
beta_init = J(1,0,.)

// ================= refresh_globals(): 从当前数据集读进所有所需矩阵 =================
void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init

    // 1) 结构变量与滞后
    X      = st_data(., ("const","l","k","lsq","ksq","m","es","es2q"))
    X_lag  = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag","lages","lages2q"))

    // 2) IV：根据 GROUP_NAME 选择
    string scalar g
    g = st_global("GROUP_NAME")
    if (g=="G1_17_19") {
        Z = st_data(., ("const","llag","k","mlag","klag","l","lsq","lages","mlagk","klages"))
    }
    else if (g=="G2_39_41") {
        Z = st_data(., ("const","llag","k","mlag","klag","l","lages","llagklag","lsq","mlagk","klages","llagmlag","ksq"))
    }
    else {
        errprintf("Invalid GROUP_NAME = [%s]\n", g)
        _error(3499)
    }

    // 3) 目标变量与控制
    PHI      = st_data(., "phi")
    PHI_lag  = st_data(., "phi_lag")
    Y        = st_data(., "r")
    C        = st_data(., "const")
    CONSOL   = st_data(., ("dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","lnage","firmcat_2","firmcat_3"))

    // 4) 起点：用最小二乘，不再手工 invsym(X'X)
    //    lsqsolve() 遇到列相关也不会报错，只给一个最小二乘解
    beta_init = lsqsolve(X, Y)'    // 行向量：1 × Kx
}

// ================= GMM 目标函数：统一用单位权重，crit = ||(1/N)Z'XI||² =================
void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, X, X_lag, Z, C, CONSOL

    real colvector OMEGA, OMEGA_lag, XI, gb, m
    real matrix POOL
    real scalar N

    // 1) 结构残差
    OMEGA     = PHI     - X     * b'
    OMEGA_lag = PHI_lag - X_lag * b'

    // 2) 控制项回归，剥离可观测成分
    if (cols(CONSOL) > 0) {
        POOL = (C, OMEGA_lag, CONSOL)
    }
    else {
        POOL = (C, OMEGA_lag)
    }
    gb = qrsolve(POOL, OMEGA)     // 最小二乘
    XI = OMEGA - POOL * gb        // 结构误差

    // 3) 样本矩条件
    N = rows(Z)
    m = quadcross(Z, XI) :/ N     // Kz × 1

    // 4) 目标函数：单位权重 ⇒ crit = ||m||²
    crit = m' * m

    // 不用自己算梯度，optimize("d0") 会自动数值差分
}

// ================== 一步 GMM：只用单位权重矩阵 I ==================
void run_one_step()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init

    real scalar N, Kx, Kz
    real scalar S1, conv1, J, df, jp
    real rowvector b
    real colvector OMEGA2, OMEGA2_lag, XI2, gb, m
    real matrix POOL2

    // 先把几个标量在 Stata 侧初始化，避免没定义
    st_numscalar("gmm_conv1", 0)
    st_numscalar("gmm_conv2", 1)
    st_numscalar("gmm_conv",  0)
    st_numscalar("J_unit",    .)
    st_numscalar("J_opt",     .)
    st_numscalar("J_df",      .)
    st_numscalar("J_p",       .)

    // 维度检查
    N  = rows(Z)
    Kx = cols(X)
    Kz = cols(Z)
    st_numscalar("Nobs", N)

    printf("\n>> [GMM-1step] N=%f, Kx=%f, Kz=%f\n", N, Kx, Kz)

    if (Kz < Kx) {
        errprintf("ERROR: Not enough instruments (Kz=%f < Kx=%f).\n", Kz, Kx)
        _error(3498)
    }

    // ===== 一步 GMM：Nelder–Mead 优化 =====
    S1 = optimize_init()
    optimize_init_evaluator(S1, &GMM_DL_weighted())
    optimize_init_evaluatortype(S1, "d0")
    optimize_init_which(S1, "min")
    optimize_init_params(S1, beta_init)
    optimize_init_technique(S1, "nm")

    optimize_init_nmsimplexdeltas(S1, J(1, cols(beta_init), 0.1))
    optimize_init_conv_maxiter(S1, 500)
    optimize_init_conv_ptol(S1, 1e-5)
    optimize_init_conv_vtol(S1, 1e-5)
    optimize_init_tracelevel(S1, "none")

    b    = optimize(S1)                    // 1 × Kx
    J    = optimize_result_value(S1)
    conv1 = optimize_result_converged(S1)

    printf("   [1-step GMM] J = %12.6f, converged = %f\n", J, conv1)

    st_numscalar("gmm_conv1", conv1)
    st_numscalar("gmm_conv",  conv1)

    // ===== 用估计值 b 计算残差、矩条件和 J 统计量 =====
    OMEGA2     = PHI     - X     * b'
    OMEGA2_lag = PHI_lag - X_lag * b'

    if (cols(CONSOL) > 0) {
        POOL2 = (C, OMEGA2_lag, CONSOL)
    }
    else {
        POOL2 = (C, OMEGA2_lag)
    }
    gb  = qrsolve(POOL2, OMEGA2)
    XI2 = OMEGA2 - POOL2 * gb

    // 平均矩条件
    m = quadcross(Z, XI2) :/ N    // Kz × 1

    // J 统计量（一步 GMM：权重矩阵 = I）
    J  = N * quadcross(m, m)
    df = Kz - Kx
    jp = .
    if (df > 0) jp = chi2tail(df, J)

    printf("\n>> [GMM-1step] J-stat : %12.4f  (df=%g, p=%6.4f)\n", J, df, jp)
    printf("   Converged (step1) : %f\n", conv1)

    // ===== 回写结果到 Stata =====
    st_matrix("beta_lin_step1", b')      // Kx × 1
    st_matrix("beta_lin",        b')      // Kx × 1
    st_matrix("g_b",             gb)      // 控制项系数（含常数、OMEGA_lag、CONSOL）

    st_matrix("moments_unit",    m')
    st_matrix("moments_opt",     m')      // 一步 GMM：两者相同

    st_numscalar("J_unit",   J)
    st_numscalar("J_opt",    J)           // 一步 GMM：J_opt = J_unit
    st_numscalar("J_df",     df)
    st_numscalar("J_p",      jp)

    // 把残差写回数据，用于 omega_hat / xi_hat
    st_store(., "OMEGA2", OMEGA2)
    st_store(., "XI2",    XI2)
}

end









* ---------- Bootstrap (cluster by firmid) ----------
program define gmm2step_once, rclass
    version 18
    syntax [, rep(integer 0)]
    
    * 记录开始时间
    timer clear 1
    timer on 1
    
    * ===== 修复 4: 增强错误处理 =====
     mata: refresh_globals()
    if _rc {
        di as err "ERROR in refresh_globals(): rc=`_rc'"
        exit _rc
    }
    
capture mata: run_one_step()
if _rc {
    local rc_mata = _rc
    di as err "ERROR in run_one_step(): rc=`rc_mata'"
    exit `rc_mata'
}


    
    * 检查收敛
    capture confirm scalar gmm_conv
    if _rc {
        di as err "gmm_conv not returned"
        exit 498
    }
    
    if scalar(gmm_conv) != 1 {
        di as txt "WARNING: GMM did not fully converge (gmm_conv=`=scalar(gmm_conv)')"
    }
    
    * 提取结果
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
    
    * 提取控制变量系数
    capture confirm matrix g_b
    if _rc {
        di as err "g_b not returned"
        exit 498
    }
    
    matrix gb = g_b
    * 按 CONSOL 顺序：gb[9] = lnage, gb[10] = firmcat_2, gb[11] = firmcat_3
    return scalar b_lnage    = gb[9,1]
    return scalar b_firmcat_2 = gb[10,1]
    return scalar b_firmcat_3 = gb[11,1]
    
    * J-statistics
    capture confirm scalar J_opt
    if !_rc return scalar J_opt = scalar(J_opt)
    
    capture confirm scalar J_p
    if !_rc return scalar J_p = scalar(J_p)
    
    * 计时
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
        global have_b0_mata 1  // 标记已获得起点
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

// full-sample 成功后，立刻抓取两个控制项系数
local b_lnage_hat     = r(b_lnage)
local b_firmcat2_hat  = r(b_firmcat_2)
local b_firmcat3_hat  = r(b_firmcat_3)

* === 全样本残差已经在 run_two_step() 中写入 OMEGA2 / XI2，这里直接用即可 ——1120添加 —— *


* === 输出 firm-level omega_hat / xi_hat（全样本） ===
capture drop omega_hat xi_hat
gen double omega_hat = OMEGA2
gen double xi_hat    = XI2

*（可选）基本健检：不应有缺失
qui count if missing(omega_hat, xi_hat)
if r(N) > 0 {
    di as txt "WARNING: `r(N)' missing values in omega_hat/xi_hat"
}

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


* ===== 在全样本估计后立即展示核心结果，方便检查 Step1 / Step2 / J =====  * ——1120添加 —— *
matrix list beta_lin_step1                                              
matrix list beta_lin                                                   
matrix list moments_unit                                               
matrix list moments_opt                                                 
scalar list J_unit J_opt J_df J_p gmm_conv                              
display as text "J_opt = " J_opt "  (df = " J_df ", p = " J_p ")"       



* —— Bootstrap 循环 —— *
di as text _n(2) "{hline 80}"
di as text "Starting bootstrap estimation (clustered by firmid)"
di as text "{hline 80}"

tempname H
tempfile bootres
local failed = 0
local total_time = 0

* === 优化 11: 固定 seed 增强可复现性 ===
set seed 20250830
local B = 2  // 调试用，正式运行请设为 200+

* === 优化 4: 记录失败原因 ===
tempfile failures
postfile failures rep reason using "`failures'", replace

postfile `H' rep double(b_const b_l b_k b_lsq b_ksq b_m b_es b_essq b_lnage b_firmcat_2 b_firmcat_3 J_opt time) ///
    using "`bootres'", replace

forvalues r = 1/`B' {
    di as text _n "Bootstrap rep `r'/`B'"
    
    preserve
        * === 修复 9: 正确重建面板结构 ===
        quietly bsample, cluster(firmid) idcluster(newfid)
        
        * 用新ID重建面板
        gen long orig_firmid = firmid
        replace firmid = newfid
        xtset firmid year
        
        * 确保T>=2
        by firmid: gen byte __T = _N
        keep if __T >= 2
        drop __T
        
        qui count
        local N_bs = r(N)
        di as text "  Sample size after keeping T>=2: `N_bs'"
        
        if (`N_bs' < 50) {
            di as txt "  WARNING: Very small sample (`N_bs' obs). May not converge."
        }
        

        
        * 估计
        capture noisily gmm2step_once, rep(`r')
        local rc = _rc
        
        if (`rc' == 0) {
            * 检查收敛
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
        
        * 仅在成功且收敛时记录
        if (`rc' == 0 & scalar(gmm_conv) == 1) {
            post `H' (`r') (r(b_c1)) (r(b_l)) (r(b_k)) (r(b_lsq)) (r(b_ksq)) (r(b_m)) ///
                   (r(b_es)) (r(b_essq)) (r(b_lnage)) (r(b_firmcat_2)) (r(b_firmcat_3)) ///
                   (r(J_opt)) (r(time))
            
            * 更新起点
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

* 保存失败记录
use "`failures'", clear
if _N > 0 {
    list, noobs
    save "bootstrap_failures_`GROUPNAME'.dta", replace
}

* 读取 bootstrap 结果
use "`bootres'", clear
if _N == 0 {
    di as err "No successful bootstrap replications. Cannot compute SEs."
    exit 430
}

* —— 计算标准误 —— *
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

* —— 附加到点估计文件 —— *
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


* —— 保存 bootstrap draws —— *
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

* === 新增：记录结束时间 ===
local end_time = c(current_time)
display as text "INFO: Script finished at `end_time'"