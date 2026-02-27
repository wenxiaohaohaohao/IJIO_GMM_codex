capture confirm global ROOT
if _rc global ROOT "D:/paper/IJIO_GMM_codex_en/methods/non_markdown_non_hicks"
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

* 纭繚 year 涓烘暟鍊煎瀷
capture confirm numeric variable year
if _rc {
    destring year, replace ignore(" -/,")
}

xtset firmid year

//鍗曚綅鎹㈢畻涓庢瀯閫犳牳蹇冨彉閲?* 骞村害姹囩巼锛堢ず渚嬫寜浣犵粰鐨?e锛?gen double e = .
replace e=8.2784 if year==2000
replace e=8.2770 if inlist(year,2001,2002,2003)
replace e=8.2768 if year==2004
replace e=8.1917 if year==2005
replace e=7.9718 if year==2006
replace e=7.6040 if year==2007

* 鍓旈櫎涓嶅悎鐞?鏃犳暟鎹?drop if domesticint <= 0
drop if 钀ヤ笟鏀跺叆鍚堣鍗冨厓 < 30

* 鏀跺叆锛堜互"褰撳勾浠锋牸鎬讳骇鍊?鎶樼編鍏冿級鈫?鏂板彉閲?R锛堢編鍏冿級
gen double R =   宸ヤ笟鎬讳骇鍊糭褰撳勾浠锋牸鍗冨厓* 1000 / e

* 璧勬湰K銆佸姵鍔↙锛堝仛鍩烘湰娓呮礂锛?rename 鍥哄畾璧勪骇鍚堣鍗冨厓 K
drop if K < 30
gen double K2=K*1000/e
rename 鍏ㄩ儴浠庝笟浜哄憳骞村钩鍧囦汉鏁颁汉 L
replace L = 骞存湯浠庝笟浜哄憳鍚堣浜?if year==2003
drop if L < 8

* 浜у嚭Q锛堢敤浣犲凡鏈夌殑 deflator锛?rename output Q1
gen double outputdef = outputdef2
gen double Q = Q1 / outputdef

* 宸ヨ祫鍩洪噾锛堢編鍏冿級
gen double WL = 搴斾粯宸ヨ祫钖叕鎬婚鍗冨厓 * 1000 / e

* 鍏跺畠鍛藉悕锛堝鏈夛級
capture confirm variable firmtotalq
if !_rc rename firmtotalq X

//鍚堝苟鎶曡祫骞冲噺鎸囨暟骞堕噸鏋勮祫鏈?merge m:1 year using "$DATA_RAW/Brandt-Rawski investment deflator.dta", nogen
replace BR_deflator = 116.7 if year == 2007  // 浣犲師鍏堢殑淇ˉ
drop if year < 2000

*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?* 2) Compute firm鈥恖evel investment I_t = K_t 鈥?K_{t-1}
*鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?bysort firmid (year): gen double I = K - K[_n-1]
bysort firmid (year): replace I = K if _n == 1

* 鏋勯€?inv0~inv19 骞剁疮璁″緱鍒?K_current
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
* 鑻ヨ鐢ㄩ噸鏋勮祫鏈紝鏀惧紑涓嬩竴琛?replace K = K_current
********************************************************************
* 鍥藉唴涓棿鎶曞叆锛堝缓璁‘璁ゅ崟浣嶏紝鑻ラ渶涔熸姌缇庡厓淇濇寔鍙ｅ緞涓€鑷达級
rename 宸ヤ笟涓棿鎶曞叆鍚堣鍗冨厓 MI
rename 绠＄悊璐圭敤鍗冨厓 Mana
replace Mana=Mana*1000/e
gen double lnR = ln(R)  if R>0
gen double lnM = ln(domesticint) if domesticint>0
ssc install winsor2, replace
winsor2 lnR, cuts(1 99) by(cic2 year) replace
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen ratio=importint/(domesticint+importint)
drop if ratio<0.02
drop if ratio>0.98
gen double lratiofs = lnR - lnM
gen SFD_ft=importint/(domesticint+importint)
*drop if SFD_ft<0.02
*drop if SFD_ft>0.98
gen S2q = SFD_ft*SFD_ft
 
//
gen inputp = inputhat + ln(inputdef2)
gen einputp = exp(inputp)
gen MF = importint/einputp
//
replace 寮€涓氭垚绔嬫椂闂村勾=. if 寮€涓氭垚绔嬫椂闂村勾==0
gen age=year-寮€涓氭垚绔嬫椂闂村勾+1
gen lnage=ln(age)
gen lnmana = ln(Mana)



******************
///鏋勯€犱竴闃跺彉閲忓苟鍋氫笁闃跺椤瑰紡鍥炲綊锛坒actor notation锛?
* 涓€闃跺鏁?gen double l  = ln(L)
gen double k  = ln(K)
gen double q  = ln(Q)
gen m = ln(delfateddomestic)        
gen double x  = ln(X)           // 纭 X 瀛樺湪
gen double r  = ln(R)
gen DWL=WL/L
gen wl=ln(DWL)

*************************************************************
* 寤鸿鑷彉閲忎篃鍙栧鏁帮紝鍙ｅ緞涓€鑷达紱鑻ヤ綘鍧氭寔鐢ㄦ按骞筹紝鍙繚鐣欎负姘村钩
* 杩欓噷淇濇寔浣犲師璁惧畾锛圞, WL, MI 鐢ㄦ按骞筹級
reg lratiofs k l wl x age lnmana i.firmtype i.city i.cic2 i.year, vce(cluster firmid)
predict double r_hat_ols, xb
*******************************************************************************
///鏋勯€犱竴闃跺彉閲忓苟鍋氫笁闃跺椤瑰紡鍥炲綊锛坒actor notation锛?

* pi / wx锛氬彧鍦ㄥ瓨鍦ㄦ椂鏀瑰悕
capture confirm variable pft
if !_rc rename pft pi

capture confirm variable foreignprice
if !_rc rename foreignprice WX

capture confirm variable WX
if !_rc gen double wx = ln(WX)

* es = 1 / exp(r_hat)
gen double es = exp(-r_hat)
gen double es2q = es^2

* 涓夐樁锛堝惈涓€闃躲€佷簩闃躲€佷笁闃舵墍鏈変氦浜掞級
reg r c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es)##c.(l k m x pi wx wl es) ///
    age i.firmtype i.city i.year

predict double phi
predict double epsilon, residuals
label var phi     "phi_it"
label var epsilon "measurement error (first stage)"

save "$DATA_WORK/firststage-nonhicksnonmd.dta", replace


