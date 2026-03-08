/*
******************************************************************************
*   Identification of Labor market monopsony with Non-neutral Productivity   *
*                                                                            *
******************************************************************************
 File Name: 03_Fig4_Tab4$5.do
 Created By:  Hui Li
 Created on:  July 2023
*/

****************************
* Path settings 
****************************
clear all
set more off, permanent

/* This sets the file paths used throughout this project. */
cd "set your path here"
global workdir    "set your path here"
global pathA      "$workdir\数据\analysis"  /*Working Data Folder*/
global pathB      "$workdir\程序\Stata"   /*Program Folder*/
global pathC      "$workdir\table"     /*Table Folder*/
global pathD      "$workdir\figure"    /*Figure Folder*/

***************************************************************
* Compare Marco weighted markdown(labor-weighted)
* ----Figure4
***************************************************************
//Load data
use "$pathA\Aggregate.dta",clear

//Compare various markdown trends
tw ///
(scatter wmd_marco year if tag==2,connect(l) color(gs8) msymbol(D) lp(dash)) ///
(scatter wmd_marco year if tag==3,connect(l) color(gs8) msymbol(T) lp(dash)) ///
(scatter wmd_marco year if tag==1,connect(l) color(maroon) lp(solid) lw(medthick)) ///
,xtitle("Year") xlabel(2008(1)2016) scheme(s2color) ///
title() /// "Panel A.中国制造业劳动折价率：2007-2016年"
ylabel(1(0.5)3, angle(0) format(%12.2f)) ytick(1(0.5)3) ytitle("劳动折价率") xtitle("年份")  ///
legend(si(msmall) cols(1) label(3 "本文方法") label(1 "Yeh et al.(2022)方法") label(2 "Pham(2023)方法") ring(0) pos(2) colgap(*0.5))  ///
graphregion(fcolor(white)) graphregion(color(white)) scale(1.1)

graph export "$pathD\Fig4.png", width(3000) replace

***************************************************************
* Compare estimation results
* ----Table 4
***************************************************************
//Load data
use "$pathA\Compare.dta",clear

* Covariance between alpha and theta
corr md_ciy_Yin md_ciy_YMH
	
* Covariance between alpha and mu
corr md_ciy_Yin md_ciy_Pham
	
* Covariance between theta and mu
corr md_ciy_YMH md_ciy_Pham

***************************************************************
* Compare estimation results
* ----Table 5
***************************************************************
//Pham(2023)
use "$pathA\Pham.dta",clear

reghdfe lnmarkdown l omega age klratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
eststo  compares_Pham

esttab  compares_Pham using "$pathC\Table5_Pham.rtf",  ///
se b(4) r2 star(* 0.10 ** 0.05 *** 0.01) onecell compress nogap replace

//YMH(2022)
use "$pathA\YMH.dta",clear

reghdfe lnmarkdown l omega age klratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
eststo  compares_YMH

esttab  compares_YMH using "$pathC\Table5_YMH.rtf",  ///
se b(4) r2 star(* 0.10 ** 0.05 *** 0.01) onecell compress nogap replace
