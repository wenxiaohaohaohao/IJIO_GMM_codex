/*
******************************************************************************
*   Identification of Labor market monopsony with Non-neutral Productivity   *
*                                                                            *
******************************************************************************
 File Name: 02_Fig3_tab3.do
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

*****************************************************
* Step two:Characteristic facts about firm markdown
* ----Figure3
*****************************************************
use "$pathA\Tax_ind.dta",clear

//Panel A of Figure3:
//Firm Size/employment share
preserve

	**Define TFP group
	bysort cic_2 year:egen tfp_5 =pctile(omiga), p(5)
	bysort cic_2 year:egen tfp_25=pctile(omiga), p(25)
	bysort cic_2 year:egen tfp_50=pctile(omiga), p(50)
	bysort cic_2 year:egen tfp_75=pctile(omiga), p(75)
	bysort cic_2 year:egen tfp_95=pctile(omiga), p(95)

	gen ltfp=.
	replace ltfp=1 if omiga<=tfp_5
	replace ltfp=2 if omiga>tfp_5  & omiga<=tfp_25
	replace ltfp=3 if omiga>tfp_25 & omiga<=tfp_50  
	replace ltfp=4 if omiga>tfp_50 & omiga<=tfp_75
	replace ltfp=5 if omiga>tfp_75 & omiga<=tfp_95
	replace ltfp=6 if omiga>tfp_95

	**Define klratio group
	bysort cic_2 year:egen klratio_5 =pctile(klratio), p(5)
	bysort cic_2 year:egen klratio_25=pctile(klratio), p(25)
	bysort cic_2 year:egen klratio_50=pctile(klratio), p(50)
	bysort cic_2 year:egen klratio_75=pctile(klratio), p(75)
	bysort cic_2 year:egen klratio_95=pctile(klratio), p(95)

	gen lklratio=.
	replace lklratio=1 if klratio<=klratio_5
	replace lklratio=2 if klratio>klratio_5  & klratio<=klratio_25
	replace lklratio=3 if klratio>klratio_25 & klratio<=klratio_50  
	replace lklratio=4 if klratio>klratio_50 & klratio<=klratio_75
	replace lklratio=5 if klratio>klratio_75 & klratio<=klratio_95
	replace lklratio=6 if klratio>klratio_95

	**Define employment share group
	bysort industry year city:egen total_l_level=sum(l_level)
	gene l_share=l_level/total_l_level

	gen llabor=.
	replace llabor=1 if l_share<=0.1
	replace llabor=2 if l_share>0.1 & l_share<=0.2
	replace llabor=3 if l_share>0.2 & l_share<=0.3 
	replace llabor=4 if l_share>0.3 & l_share<=0.4
	replace llabor=5 if l_share>0.4 & l_share<=0.5
	replace llabor=6 if l_share>0.5 & l_share<=0.6
	replace llabor=7 if l_share>0.6 & l_share<=0.7 
	replace llabor=8 if l_share>0.7 & l_share<=0.8
	replace llabor=9 if l_share>0.8 & l_share<=0.9
	replace llabor=10 if l_share>0.9

	**Define age group
	drop if age<0
	gen lage=.
	replace lage=1 if age<=2 & age>=0
	replace lage=2 if age<=5 & age>=3
	replace lage=3 if age<=8 & age>=6
	replace lage=4 if age<=11 & age>=9
	replace lage=5 if age<=14 & age>=12
	replace lage=6 if age>=15

	//Plot
	reghdfe lnmarkdown i.llabor i.ltfp i.lage i.lklratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
	eststo fig2a

	coefplot (fig2a, recast(connect) lcolor("127 0 0") mc("127 0 0") lw(medium) lp(solid)) ///
	, baselevels ///
	keep(1.llabor 2.llabor 3.llabor 4.llabor 5.llabor 6.llabor 7.llabor 8.llabor 9.llabor 10.llabor) ///
	vertical ///
	coeflabels( ///
	1.llabor ="0.1" ///
	2.llabor ="0.2" ///
	3.llabor ="0.3" ///
	4.llabor ="0.4" ///
	5.llabor ="0.5" ///
	6.llabor ="0.6" ///
	7.llabor ="0.7" ///
	8.llabor ="0.8" ///
	9.llabor ="0.9" ///
	10.llabor="1")  ///
	ytitle("劳动折价率") ///
	xtitle("企业规模") ///
	ylabel(,angle(0) format(%12.2f)) ///
	ciopts(fcolor(maroon%15) recast(rarea) lwidth(thin) lpattern(dash) color(maroon*0.15)) ///
	addplot(line @b @at,lcolor("127 0 0") lp(solid)) ///
	graphregion(fcolor(white) lc(white)) ///
	plotregion(lcolor(black) lwidth(none)) ///
	yline(0,lcolor(gs8) lp(dash)) ///
    title("Panel A:企业规模和劳动折价率", color(black) pos(11) size(12pt) margin(small)) ///
    scale(1.3) 

	graph export "$pathD/Fig3a.png", width(3000) replace

restore

//Panel B of Figure2:
//Firm TFP
preserve

	**Define TFP group
	bysort cic_2 year:egen tfp_5 =pctile(omiga), p(5)
	bysort cic_2 year:egen tfp_25=pctile(omiga), p(25)
	bysort cic_2 year:egen tfp_50=pctile(omiga), p(50)
	bysort cic_2 year:egen tfp_75=pctile(omiga), p(75)
	bysort cic_2 year:egen tfp_95=pctile(omiga), p(95)

	gen ltfp=.
	replace ltfp=1 if omiga<=tfp_5
	replace ltfp=2 if omiga>tfp_5  & omiga<=tfp_25
	replace ltfp=3 if omiga>tfp_25 & omiga<=tfp_50  
	replace ltfp=4 if omiga>tfp_50 & omiga<=tfp_75
	replace ltfp=5 if omiga>tfp_75 & omiga<=tfp_95
	replace ltfp=6 if omiga>tfp_95

	**Define klratio group
	bysort cic_2 year:egen klratio_5 =pctile(klratio), p(5)
	bysort cic_2 year:egen klratio_25=pctile(klratio), p(25)
	bysort cic_2 year:egen klratio_50=pctile(klratio), p(50)
	bysort cic_2 year:egen klratio_75=pctile(klratio), p(75)
	bysort cic_2 year:egen klratio_95=pctile(klratio), p(95)

	gen lklratio=.
	replace lklratio=1 if klratio<=klratio_5
	replace lklratio=2 if klratio>klratio_5  & klratio<=klratio_25
	replace lklratio=3 if klratio>klratio_25 & klratio<=klratio_50  
	replace lklratio=4 if klratio>klratio_50 & klratio<=klratio_75
	replace lklratio=5 if klratio>klratio_75 & klratio<=klratio_95
	replace lklratio=6 if klratio>klratio_95

	**Define share group
	bysort industry year city:egen total_l_level=sum(l_level)
	gene l_share=l_level/total_l_level

	gen llabor=.
	replace llabor=1 if l_share<=0.1
	replace llabor=2 if l_share>0.1 & l_share<=0.2
	replace llabor=3 if l_share>0.2 & l_share<=0.3 
	replace llabor=4 if l_share>0.3 & l_share<=0.4
	replace llabor=5 if l_share>0.4 & l_share<=0.5
	replace llabor=6 if l_share>0.5 & l_share<=0.6
	replace llabor=7 if l_share>0.6 & l_share<=0.7 
	replace llabor=8 if l_share>0.7 & l_share<=0.8
	replace llabor=9 if l_share>0.8 & l_share<=0.9
	replace llabor=10 if l_share>0.9

	**Define age group
	drop if age<0
	gen lage=.
	replace lage=1 if age<=2 & age>=0
	replace lage=2 if age<=5 & age>=3
	replace lage=3 if age<=8 & age>=6
	replace lage=4 if age<=11 & age>=9
	replace lage=5 if age<=14 & age>=12
	replace lage=6 if age>=15

	//Plot
	reghdfe lnmarkdown i.llabor i.ltfp i.lage i.lklratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
	eststo fig2b

	coefplot (fig2b, recast(connect) lcolor("127 0 0") mc("127 0 0") lw(medium) lp(solid)) ///
	, baselevels ///
	keep(1.ltfp 2.ltfp 3.ltfp 4.ltfp 5.ltfp 6.ltfp) ///
	vertical ///
	coeflabels( ///
	1.ltfp ="0-5" ///
	2.ltfp ="5-25" ///
	3.ltfp ="25-50" ///
	4.ltfp ="50-75" ///
	5.ltfp ="75-95" ///
	6.ltfp ="95-100")  ///
	yline(0,lcolor(maroon*0.8) lp(dash)) ///
	ytitle("劳动折价率") ///
	xtitle("企业生产率分位(%)") ///
	ylabel(,angle(0) format(%12.2f)) ///
	ciopts(fcolor(maroon%15) recast(rarea) lwidth(thin) lpattern(dash) color(maroon*0.15)) ///
	addplot(line @b @at,lcolor("127 0 0") lp(solid)) ///
	graphregion(fcolor(white) lc(white)) ///
	plotregion(lcolor(black) lwidth(none)) ///
	yline(0,lcolor(gs8) lp(dash)) ///
    title("Panel B:企业生产率和劳动折价率", color(black) pos(11) size(12pt) margin(small)) ///
    scale(1.3) 

	graph export "$pathD/Fig3b.png", width(3000) replace

restore

//Panel C of Figure3:
//Firm capital/labor ratio
preserve

	**Define TFP group
	bysort cic_2 year:egen tfp_5 =pctile(omiga), p(5)
	bysort cic_2 year:egen tfp_25=pctile(omiga), p(25)
	bysort cic_2 year:egen tfp_50=pctile(omiga), p(50)
	bysort cic_2 year:egen tfp_75=pctile(omiga), p(75)
	bysort cic_2 year:egen tfp_95=pctile(omiga), p(95)

	gen ltfp=.
	replace ltfp=1 if omiga<=tfp_5
	replace ltfp=2 if omiga>tfp_5  & omiga<=tfp_25
	replace ltfp=3 if omiga>tfp_25 & omiga<=tfp_50  
	replace ltfp=4 if omiga>tfp_50 & omiga<=tfp_75
	replace ltfp=5 if omiga>tfp_75 & omiga<=tfp_95
	replace ltfp=6 if omiga>tfp_95

	**Define klratio group
	bysort cic_2 year:egen klratio_5 =pctile(klratio), p(5)
	bysort cic_2 year:egen klratio_25=pctile(klratio), p(25)
	bysort cic_2 year:egen klratio_50=pctile(klratio), p(50)
	bysort cic_2 year:egen klratio_75=pctile(klratio), p(75)
	bysort cic_2 year:egen klratio_95=pctile(klratio), p(95)

	gen lklratio=.
	replace lklratio=1 if klratio<=klratio_5
	replace lklratio=2 if klratio>klratio_5  & klratio<=klratio_25
	replace lklratio=3 if klratio>klratio_25 & klratio<=klratio_50  
	replace lklratio=4 if klratio>klratio_50 & klratio<=klratio_75
	replace lklratio=5 if klratio>klratio_75 & klratio<=klratio_95
	replace lklratio=6 if klratio>klratio_95

	**Define share group
	bysort industry year city:egen total_l_level=sum(l_level)
	gene l_share=l_level/total_l_level

	gen llabor=.
	replace llabor=1 if l_share<=0.1
	replace llabor=2 if l_share>0.1 & l_share<=0.2
	replace llabor=3 if l_share>0.2 & l_share<=0.3 
	replace llabor=4 if l_share>0.3 & l_share<=0.4
	replace llabor=5 if l_share>0.4 & l_share<=0.5
	replace llabor=6 if l_share>0.5 & l_share<=0.6
	replace llabor=7 if l_share>0.6 & l_share<=0.7 
	replace llabor=8 if l_share>0.7 & l_share<=0.8
	replace llabor=9 if l_share>0.8 & l_share<=0.9
	replace llabor=10 if l_share>0.9

	**Define age group
	drop if age<0
	gen lage=.
	replace lage=1 if age<=2 & age>=0
	replace lage=2 if age<=5 & age>=3
	replace lage=3 if age<=8 & age>=6
	replace lage=4 if age<=11 & age>=9
	replace lage=5 if age<=14 & age>=12
	replace lage=6 if age>=15

	//Plot
	reghdfe lnmarkdown i.llabor i.ltfp i.lage i.lklratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
	eststo fig3a

	coefplot (fig3a, recast(connect) lcolor("127 0 0") mc("127 0 0") lw(medium) lp(solid)) ///
	, baselevels ///
	keep(1.lklratio 2.lklratio 3.lklratio 4.lklratio 5.lklratio 6.lklratio) ///
	vertical ///
	coeflabels( ///
	1.lklratio ="0-5" ///
	2.lklratio ="5-25" ///
	3.lklratio ="25-50" ///
	4.lklratio ="50-75" ///
	5.lklratio ="75-95" ///
	6.lklratio ="95-100")  ///
	yline(0,lcolor(maroon*0.8) lp(dash)) ///
	ytitle("劳动折价率") ///
	xtitle("企业资本劳动比分位(%)") ///
	ylabel(,angle(0) format(%12.2f)) ///
	ciopts(fcolor(maroon%15) recast(rarea) lwidth(thin) lpattern(dash) color(maroon*0.15)) ///
	addplot(line @b @at,lcolor("127 0 0") lp(solid)) ///
	graphregion(fcolor(white) lc(white)) ///
	plotregion(lcolor(black) lwidth(none)) ///
	yline(0,lcolor(gs8) lp(dash)) ///
    title("Panel C:企业资本劳动比和劳动折价率", color(black) pos(11) size(12pt) margin(small)) ///
    scale(1.3) 

	graph export "$pathD/Fig3c.png", width(3000) replace

restore

//Panel D of Figure3:
//Firm Age
preserve

	**Define TFP group
	bysort cic_2 year:egen tfp_5 =pctile(omiga), p(5)
	bysort cic_2 year:egen tfp_25=pctile(omiga), p(25)
	bysort cic_2 year:egen tfp_50=pctile(omiga), p(50)
	bysort cic_2 year:egen tfp_75=pctile(omiga), p(75)
	bysort cic_2 year:egen tfp_95=pctile(omiga), p(95)

	gen ltfp=.
	replace ltfp=1 if omiga<=tfp_5
	replace ltfp=2 if omiga>tfp_5  & omiga<=tfp_25
	replace ltfp=3 if omiga>tfp_25 & omiga<=tfp_50  
	replace ltfp=4 if omiga>tfp_50 & omiga<=tfp_75
	replace ltfp=5 if omiga>tfp_75 & omiga<=tfp_95
	replace ltfp=6 if omiga>tfp_95

	**Define klratio group
	bysort cic_2 year:egen klratio_5 =pctile(klratio), p(5)
	bysort cic_2 year:egen klratio_25=pctile(klratio), p(25)
	bysort cic_2 year:egen klratio_50=pctile(klratio), p(50)
	bysort cic_2 year:egen klratio_75=pctile(klratio), p(75)
	bysort cic_2 year:egen klratio_95=pctile(klratio), p(95)

	gen lklratio=.
	replace lklratio=1 if klratio<=klratio_5
	replace lklratio=2 if klratio>klratio_5  & klratio<=klratio_25
	replace lklratio=3 if klratio>klratio_25 & klratio<=klratio_50  
	replace lklratio=4 if klratio>klratio_50 & klratio<=klratio_75
	replace lklratio=5 if klratio>klratio_75 & klratio<=klratio_95
	replace lklratio=6 if klratio>klratio_95

	**Define share group
	bysort industry year city:egen total_l_level=sum(l_level)
	gene l_share=l_level/total_l_level

	gen llabor=.
	replace llabor=1 if l_share<=0.1
	replace llabor=2 if l_share>0.1 & l_share<=0.2
	replace llabor=3 if l_share>0.2 & l_share<=0.3 
	replace llabor=4 if l_share>0.3 & l_share<=0.4
	replace llabor=5 if l_share>0.4 & l_share<=0.5
	replace llabor=6 if l_share>0.5 & l_share<=0.6
	replace llabor=7 if l_share>0.6 & l_share<=0.7 
	replace llabor=8 if l_share>0.7 & l_share<=0.8
	replace llabor=9 if l_share>0.8 & l_share<=0.9
	replace llabor=10 if l_share>0.9

	**Define age group
	drop if age<0
	gen lage=.
	replace lage=1 if age<=2 & age>=0
	replace lage=2 if age<=5 & age>=3
	replace lage=3 if age<=8 & age>=6
	replace lage=4 if age<=11 & age>=9
	replace lage=5 if age<=14 & age>=12
	replace lage=6 if age>=15

	//Plot
	reghdfe lnmarkdown i.llabor i.ltfp i.lage i.lklratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
	eststo fig3b

	coefplot (fig3b, recast(connect) lcolor("127 0 0") mc("127 0 0") lw(medium) lp(solid)) ///
	, baselevels ///
	keep(1.lage 2.lage 3.lage 4.lage 5.lage 6.lage) ///
	vertical ///
	coeflabels( ///
	1.lage ="0-2" ///
	2.lage ="3-5" ///
	3.lage ="6-8" ///
	4.lage ="9-11" ///
	5.lage ="12-14" ///
	6.lage ="15+") ///
	yline(0,lcolor(maroon*0.8) lp(dash)) ///
	ytitle("劳动折价率") ///
	xtitle("企业年龄") ///
	ylabel(,angle(0) format(%12.2f)) ///
	ciopts(fcolor(maroon%15) recast(rarea) lwidth(thin) lpattern(dash) color(maroon*0.15)) ///
	addplot(line @b @at,lcolor("127 0 0") lp(solid)) ///
	graphregion(fcolor(white) lc(white)) ///
	plotregion(lcolor(black) lwidth(none)) ///
	yline(0,lcolor(gs8) lp(dash)) ///
    title("Panel D:企业年龄和劳动折价率", color(black) pos(11) size(12pt) margin(small)) ///
    scale(1.3) 

	graph export "$pathD/Fig3d.png", width(3000) replace

	//Table 4:
	// Firm R&D and Export
	reghdfe lnmarkdown i.llabor i.ltfp i.lage i.lklratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
	eststo  reg1
	reghdfe lnmarkdown i.llabor i.ltfp i.lage i.lklratio export_dummy rd_dummy,absorb(i.year#i.cic_2 i.year#i.county) cluster(cic_2)
	eststo  reg2

	esttab  reg* using "$pathC\Tab3.rtf", keep(export_dummy rd_dummy)  ///
	se b(4) r2 star(* 0.10 ** 0.05 *** 0.01) onecell compress nogap replace 

	//Table5-Yin
	reghdfe lnmarkdown l omiga age klratio export_dummy rd_dummy,absorb(i.year i.cic_2 i.county) cluster(cic_2)
	eststo  compares_Yin
	
	* Output
	esttab  compares_Yin using "$pathC\Table5_Yin.rtf",  ///
	se b(4) r2 star(* 0.10 ** 0.05 *** 0.01) onecell compress nogap replace 

restore

