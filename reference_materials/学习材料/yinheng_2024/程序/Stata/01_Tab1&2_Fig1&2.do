/*
******************************************************************************
*   Identification of Labor market monopsony with Non-neutral Productivity   *
*                                                                            *
******************************************************************************
 File Name: 01_Tabl&2_Fig1&2.do
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

*************************************************************************************
* Step one: Calculate industry weighted elasticity & markdown
*************************************************************************************
//Load data
forvalues ind=1(1)10{

  	use "$pathA\Tax_ind.dta",clear
	keep if industry==`ind'

	bysort year:egen suml_level=total(l_level)
	bysort year:egen sumy_level=total(y_level)

	//Revenue elasticity
	gene wrbeidal_firm=(y_level/sumy_level)*rbeidal //Revenue elasticity of Labor 
	bysort year:egen wrbeidal=total(wrbeidal_firm)

	gene wrbeidam_firm=(y_level/sumy_level)*rbeidam //Revenue elasticity of Material 
	bysort year:egen wrbeidam=total(wrbeidam_firm)

	gene wrbeidak_firm=(y_level/sumy_level)*rbeidak //Revenue elasticity of Capital
	bysort year:egen wrbeidak=total(wrbeidak_firm)

	//Markdown
	gene wmd_firm=(l_level/suml_level)*markdown 
	bysort year:egen wmd=total(wmd_firm)            //Weighted average Markdown

	bysort year:egen md_p50=pctile(markdown),p(50)  //Median Markdown
	bysort year:egen md_p25=pctile(markdown),p(25)
	bysort year:egen md_p75=pctile(markdown),p(75)
	gene iqr_md=ln(md_p75)-ln(md_p25)               //IQR of Markdown

    bysort year:egen md_sd=sd(markdown)             //Std of Markdown

	drop wrbeidal_firm wrbeidam_firm wrbeidak_firm wmd_firm wrbeidal_firm

    //Calculate markdown autocorrelation
    xtset id year
    asdoc cor markdown l.markdown, save($pathC/Tab2_autocorreation.doc) title(Autocorrelation of `ind') format(%9.4f) append
 	save "$pathA\Tax_ind_temp`ind'.dta",replace
}


***********************************************
* Step two:calculate productivity 
***********************************************
forvalues ind=1(1)10{

  	use "$pathA\Tax_ind.dta",clear
	keep if industry==`ind'

    // looping over 2 productivity definitions: omiga,lomiga
    foreach prod in omiga lomiga {

        **Standard deviation: ysd`prod'

        quietly su `prod',de 
        gene sdv`prod' = r(sd)  // this calculates Standard deviation of all years.
        bysort year: egen ysd`prod'=sd(`prod')  // this calculates Standard deviation by year.

        gene ex`prod' = exp(`prod')
        quietly su ex`prod',de
        gene iqr`prod'4 = r(p75)/r(p25)

        bysort year : egen `prod'75 = pctile(`prod'),p(75)  
        bysort year : egen `prod'25 = pctile(`prod'),p(25)  
        gene yiqr`prod'4 = `prod'75-`prod'25 

        drop ex`prod' `prod'75 `prod'25
    }

    //looping over 2 productivity definitions: omiga,lomiga
    foreach prod in omiga lomiga {

        **Outliers of weights(y_level)
        gene y_levela = y_level
        bysort year industry: egen plow = pctile(y_levela),p(1)
        bysort year industry: egen phigh= pctile(y_levela),p(99)
        replace y_levela = . if y_levela >= phigh |  y_levela <= plow 
        drop plow phigh

        **Outliers of `prod'
        foreach outliers in omiga lomiga  {
            gene `outliers'a = `outliers'
            bysort year industry: egen plow = pctile(`outliers'a),p(1)
            bysort year industry: egen phigh= pctile(`outliers'a),p(99)
            replace `outliers'a = . if `outliers'a >= phigh | `outliers'a <= plow
            replace y_levela = . if `outliers'a==.
            drop plow phigh `outliers'a
        }

        **Then, calculate the weighted average of productivity by year: w`prod' (weights by revenue)
        bysort year: egen sumy_levela = total(y_levela)
        gene double w`prod'_firm = (y_levela/sumy_levela) * `prod'
        bysort year: egen double w`prod' = total(w`prod'_firm)
        drop sumy_levela w`prod'_firm  y_levela 

    //calculate annual & cumulative weighted average of `prod' growth rate by year: wd`prod'm2 & cwd`prod'm2

        gene wd`prod'm2  = .  // this generates weighted productivity growth rate by year
        gene cwd`prod'm2 = . // this generates cumulative weighted productivity growth rate by year

        preserve

            duplicates drop year,force  //keeping only 1 observation per industry-year cell
            xtset industry year
            replace  wd`prod'm2 = w`prod' - l.w`prod'
            replace cwd`prod'm2 = 0 if year == 2008
            replace cwd`prod'm2 = l.cwd`prod'm2 + wd`prod'm2 if year>2008

            forvalues year=2008(1)2016{
                quietly su cwd`prod'm2 if year == `year',de
                scalar cwd`prod'm2`year' = r(mean)
                quietly su wd`prod'm2 if year == `year',de
                scalar wd`prod'm2`year' = r(mean)
            }

        restore

        forvalues year=2008(1)2016 {
            replace  cwd`prod'm2 = cwd`prod'm2`year' if year ==`year'  //this replaces annual cw`prod'm1 in firm level
            replace  wd`prod'm2  = wd`prod'm2`year' if year ==`year'  //this replaces annual cw`prod'm1 in firm level
        }

    * Finally, calculate annual productivity growth rate.
        quietly su cwd`prod'm2 if year==2016,de
        scalar cwd`prod'm22016 = r(mean)

        gene cwd`prod'm20816 = cwd`prod'm22016  // this uses cumulative productivity growth rate in 2007
        gene cwd`prod'm20816_anu = cwd`prod'm20816/8
 
    }  // closing the productivity loop

    duplicates drop year,force //keeping only 1 observation per year

    //Output lomiga results
    preserve

    estpost tabstat cwdlomigam20816_anu yiqrlomiga4 ///
    ,listwise statistics(mean) columns(statistics)

    esttab . using "$pathC/table_temp.csv" , replace ///
    cells("mean") 
    
    insheet using "$pathC/table_temp.csv", comma clear
    export excel "$pathC/Tab1_lomiga.xls", sheetreplace sheet(`ind') 
    erase "$pathC/table_temp.csv"

    restore

}  // closing the industry loop

***************************************************************
* Step three: Output estimated result table
* ----Table 1 & Table 2
***************************************************************
//load data
use "$pathA\Tax_ind_temp1.dta",clear

forvalues ind=2(1)10{
  append using "$pathA\Tax_ind_temp`ind'.dta"
}

preserve

	egen ciy = group(city industry year)
	by ciy, sort: egen l_ciy = sum(l_level)	
	gen s_ciy = l_level/l_ciy
	by ciy, sort: egen md_ciy_Yin = total(markdown*s_ciy)
	duplicates drop ciy,force
	keep city industry year md_ciy_Yin
	gene tag = 1 
	save "$pathA\Yin_local.dta",replace

restore

//Calculate marco weighted markdown
duplicates drop year industry,force

merge m:1 year industry using "$pathA\industry_share_labor_cic_1.dta", keep(1 3)
bysort year :egen wmd_marco=sum(wmd*share)      //weighted average markdown(weighted by marco-industry-labor)
bysort year :egen medmd_marco=sum(md_p50*share) //weighted median markdown (weighted by marco-industry-labor)

//Table 1 & Table 2:Output marco markodwn results
estpost tabstat bm wrbeidak wrbeidal wrbeidam ///
wmd md_p50 iqr_md md_sd, ///
by(industry) listwise statistics(mean) columns(statistics)

esttab . using "$pathC/Tab1_Tab2.csv", replace ///
cells("mean") 

***************************************************************
* Step four:Plot Marco weighted markdown(labor-weighted)
* ----Figure1
***************************************************************
duplicates drop year,force
gene tag = 1 
keep year tag wmd_marco medmd_marco 

tw ///
(scatter wmd_marco year,connect(l) color(maroon) lp(solid)) ///
(scatter medmd_marco year,connect(l) color(navy*0.7) msymbol(D) lp(dash)) ///
,xtitle("Year") xlabel(2008(1)2016) scheme(s2color) ///
title() ///"Panel A.中国制造业劳动折价率：2007-2016年"
ylabel(1(0.5)2.5, angle(0) format(%12.2f)) ytick(1(0.1)2.5) ytitle("劳动折价率") xtitle("年份")  ///
legend(si(msmall) cols(1) label(1 "加权均值") label(2 "中位数") ring(0) pos(2) colgap(*0.5))  ///
graphregion(fcolor(white)) graphregion(color(white)) scale(1.2)

graph export "$pathD\Fig1.png", width(3000) replace

//save data
save "$pathA\Agg_markdown_Yin.dta",replace

*******************************************
* Step five:Calculate markdown by province
* ----Figure2
*******************************************
//Append industry data 
use "$pathA\prov_md.dta",clear

graph bar (mean) markdown, over(province, sort(id) gap(10) label(angle(90))) ///  
bargap(20) bar(1, color(navy)) ///  
title("分省份劳动折价率分布") ///  
ytitle("劳动折价率", orientation(vertical)) ///  
legend(off) scheme(s1mono)

graph export "$pathD\Fig2.png", width(3000) replace

//erase data
forvalues ind=1(1)10{
  capture erase "$pathA\Tax_ind_temp`ind'.dta"
}
