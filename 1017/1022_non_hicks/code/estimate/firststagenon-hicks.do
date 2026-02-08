capture confirm global ROOT
if _rc global ROOT "D:/文章发表/欣昊/input markdown/IJIO/IJIO_GMM_codex/1017/1022_non_hicks"
global CODE "$ROOT/code"
global DATA_RAW "$ROOT/data/raw"
global DATA_WORK "$ROOT/data/work"
global RES_DATA "$ROOT/results/data"
global RES_FIG "$ROOT/results/figures"
global RES_LOG "$ROOT/results/logs"


clear all
cd "$ROOT"

use "$DATA_RAW/junenewg_0902", clear

duplicates drop firmid year, force

* 确保 year 为数值型
capture confirm numeric variable year
if _rc {
    destring year, replace ignore(" -/,")
}

xtset firmid year

//单位换算与构造核心变量
* 年度汇率（示例按你给的 e）
gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

* 剔除不合理/无数据
drop if domesticint <= 0
drop if 营业收入合计千元 < 30

* 收入（以"当年价格总产值"折美元）→ 新变量 R（美元）
gen double R =   工业总产值_当年价格千元* 1000 / e

* 资本K、劳动L（做基本清洗）
rename 固定资产合计千元 K
drop if K < 30
gen double K2=K*1000/e
rename 全部从业人员年平均人数人 L
replace L = 年末从业人员合计人 if year==2003
drop if L < 8

* 产出Q（用你已有的 deflator）
rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

* 工资基金（美元）
gen double WL = 应付工资薪酬总额千元 * 1000 / e

* 其它命名（如有）
capture confirm variable firmtotalq
if !_rc rename firmtotalq X

//合并投资平减指数并重构资本
merge m:1 year using "$DATA_RAW/Brandt-Rawski investment deflator.dta", nogen
replace BR_deflator = 116.7 if year == 2007  // 你原先的修补
drop if year < 2000

*———————————————————————————————
* 2) Compute firm‐level investment I_t = K_t – K_{t-1}
*———————————————————————————————
bysort firmid (year): gen double I = K - K[_n-1]
bysort firmid (year): replace I = K if _n == 1

* 构造 inv0~inv19 并累计得到 K_current
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
sum K_current, detail
* 若要用重构资本，放开下一行
replace K = K_current
********************************************************************
* 国内中间投入（建议确认单位，若需也折美元保持口径一致）
rename 工业中间投入合计千元 MI
rename 管理费用千元 Mana
replace Mana=Mana*1000/e
gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0
ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen ratio=importint/(domesticint+importint)
drop if ratio<0.02
*drop if ratio>0.98
gen double lratiofs = lnR - lnM
 
//
gen inputp = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF = importint/einputp
//
replace 开业成立时间年=. if 开业成立时间年==0
gen age=year-开业成立时间年+1
gen lnage=ln(age)
gen lnmana = ln(Mana)

******************
///构造一阶变量并做三阶多项式回归（factor notation）

* 一阶对数
gen double l  = ln(L)
gen double k  = ln(K)
gen double q  = ln(Q)
gen m = ln(delfateddomestic)        
gen double x  = ln(X)           // 确认 X 存在
gen double r  = ln(R)
gen DWL=WL/L
gen wl=ln(DWL)

*************************************************************
* 建议自变量也取对数，口径一致；若你坚持用水平，可保留为水平
* 这里保持你原设定（K, WL, MI 用水平）
reg lratiofs k l wl x age lnmana i.firmtype i.city i.cic2 i.year, vce(cluster firmid)
predict double r_hat_ols, xb
*******************************************************************************
///构造一阶变量并做三阶多项式回归（factor notation）

* pi / wx：只在存在时改名
capture confirm variable pft
if !_rc rename pft pi

capture confirm variable foreignprice
if !_rc rename foreignprice WX

capture confirm variable WX
if !_rc gen double wx = ln(WX)

* es = 1 / exp(r_hat)
gen double es = exp(-r_hat)
gen double es2q = es^2

* 三阶（含一阶、二阶、三阶所有交互）
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmtype i.city i.year

predict double phi
predict double epsilon, residuals
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"

save "$DATA_WORK/firststage-nonhicks.dta", replace

