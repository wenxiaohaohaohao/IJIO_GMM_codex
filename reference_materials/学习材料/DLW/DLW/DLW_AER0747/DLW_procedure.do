clear mata
*ACF PROCEDURE DE LOECKER-WARZYNSKI
*-April 2, 2010
*-----------------------------------------------------------------------------------------------------*
*LEVEL APPROACH: 1/estimate coefficient, 2/use 'corrected' revenue share to back out markup by i
*correction is based on estimate of measurement error, /epsilon in our framework.
*VALUE ADDED PF FRAMEWORK: implies that markup is computed of beta_l 
*----------------------------------------------------------------------------------------------------*
qui{
* LOAD DATA
clear
set mem 400m
//Select industry for procedure
keep if industry==`i'
*---------------creating variables--------------------------------------------------------------------*
* higher order terms on inputs
local M=3
local N=3
forvalues i=1/`M' {
gen l`i'=l^(`i')
gen m`i'=m^(`i')
gen k`i'=k^(`i')
*interaction terms
forvalues j=1/`N' {
gen l`i'm`j'=l^(`i')*m^(`j')
gen l`i'k`j'=l^(`i')*k^(`j')
gen k`i'm`j'=k^(`i')*m^(`j')
}
}
gen lkm=l*k*m
gen l2k2m2=l2*k2*m2
gen l3k3m3=l3*k3*m3
* generate interaction terms of all (l,m,k) with exportdummy:call all terms e*(.) below
*----------------------------------------------------------------------------------------------------*
* OLS REGRESSION FOR STARTING VALUES
xi: reg y l k i.nace2 i.year
gen blols=_b[l]
gen bkols=_b[k]
*------FIRST STAGE USING EXP AS INPUT  ----------------------------------------------------------*
xi: reg y e*(l* m* k*) i.year
predict phi
predict epsilon, res
label var phi "phi_it 
label var epsilon "measurement error first stage
gen phi_lag=L.phi
gen exp_lag=L.e
*----------------------------------------------------------------------------------------------------*
gen l_lag=L.l
gen k_lag=L.k
gen l_lag2=l_lag^2
gen k_lag2=k_lag^2
gen l_lagk_lag=l_lag*k_lag
gen lk=l*k
gen l_lagk=l_lag*k
*---COMPUTE CORRECTED SHARES------------------为什么这么做？-------------------------------------------------------*
gen y_c=lva-epsilon
gen va_c=exp(y_c)
gen alpha_l=wagebill/va_c
*---------------------------------------------------------------------------------------------------*
drop _I*
sort fid year
gen const=1
drop if y==.
drop if l_lag==.
drop if k==.
drop if phi==.
drop if phi_lag==.
}

/* FOR SKETCH CODE BELOW WE USE AR1 PROCESS ON PRODUCTIVITY, IN PAPER WE USE POLYNOMIAL EXPANSION AND HAVE
HIGHER ORDER TERMS IN OMEGA_LAG_POL
*/
qui{
*-------------------------------------BEGIN MATA PROGRAM--------------------------------------------*
mata:
void GMM_DLW(todo,betas,crit,g,H)
{
	PHI=st_data(.,("phi"))
    PHI_LAG=st_data(.,("phi_lag"))
    Z=st_data(.,("const","l_lag","k"))
    X=st_data(.,("const","l","k"))
    X_lag=st_data(.,("const","l_lag","k_lag"))
    Y=st_data(.,("y"))
    C=st_data(.,("const"))

	OMEGA=PHI-X*betas'
	OMEGA_lag=PHI_LAG-X_lag*betas'
	OMEGA_lag_pol=(C,OMEGA_lag)
	g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
	XI=OMEGA-OMEGA_lag_pol*g_b
	crit=(Z'XI)'(Z'XI)
}



    void GMM_DLW_TL(todo,betas,crit,g,H)
{
	PHI=st_data(.,("phi"))
	PHI_LAG=st_data(.,("phi_lag"))
	Z=st_data(.,("const","l_lag","k","l_lag2","k2","l_lagk"))
	X=st_data(.,("const","l","k","l2","k2","lk"))
	X_lag=st_data(.,("const","l_lag","k_lag","l_lag2","k_lag2","l_lagk_lag"))
	Y=st_data(.,("y"))
	C=st_data(.,("const"))

	OMEGA=PHI-X*betas'
	OMEGA_lag=PHI_LAG-X_lag*betas'
	OMEGA_lag_pol=(C,OMEGA_lag)
	g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
	XI=OMEGA-OMEGA_lag_pol*g_b
	crit=(Z'XI)'(Z'XI)
}

void DLW()
	{
S=optimize_init()
optimize_init_evaluator(S, &GMM_DLW())
optimize_init_evaluatortype(S,"d0")
optimize_init_technique(S, "nm")
optimize_init_nmsimplexdeltas(S, 0.1)
optimize_init_which(S,"min")
optimize_init_params(S,("OLS"))
p=optimize(S)
p
st_matrix("beta_dlw",p)
}

void DLW_TRANSLOG()
	{
S=optimize_init()
optimize_init_evaluator(S, &GMM_DLW_TL())
optimize_init_evaluatortype(S,"d0")
optimize_init_technique(S, "nm")
optimize_init_nmsimplexdeltas(S, 0.1)
optimize_init_which(S,"min")
optimize_init_params(S,(0,0,0,0,0,0))
p=optimize(S)
p
st_matrix("beta_dlwtranslog",p)
}

*-----------------------------------------END MATA PROGRAM---------------------------------------*
cap program drop dlw
program dlw, rclass
preserve 
sort Id year
mata DLW()
end
*------------------------------------------------------------------------------------------------*
cap program drop dlw_translog
program dlw_translog, rclass
preserve
sort Id year
mata DLW_TRANSLOG()
end
*------------------------------------COMPUTE MARKUPS --------------------------------------------*
// OLS, DLW estimates for variable input (here labor) are used to compute markup distribution

*------------------------------------OLS estimates-----------------------------------------------*
reg y l k i.year
gen beta_lols=_b[l]
gen beta_kols=_b[k]
gen Markup_ols=_b[l]/alpha_l
*------------------------------------ACF estimates-----------------------------------------------*
dlw
gen beta_c1=beta_dlwf[1,1]
gen beta_l1=beta_dlw[1,2]
gen beta_k1=beta_dlw[1,3]
gen Markup_dlw1=beta_l1/alpha_l
gen omega_dlw1=phi-beta_l1*l-beta_k1*k
*-------------------------------------------------------------------------------------------------*
dlw_translog
gen betal_tl1=beta_dlwtranslog[1,2]
gen betal_tl2=beta_dlwtranslog[1,4]
gen betak_tl1=beta_dlwtranslog[1,3]
gen betak_tl2=beta_dlwtranslog[1,5]
gen betalk_tl=beta_dlwtranslog[1,6]
gen betal_tl=betal_tl1+2*betal_tl2*l+betalk_tl*k
gen Markup_DLWTL=betal_tl/alpha_l
*-------------------------------------------------------------------------------------------------*

* collect markup estimates and productivity for analysis:
gen mu_1=Markup_dlw1
gen mu_2=Markup_dlw2
gen mu_3=Markup_DLWTL
*-------------------------------------------------------------------------------------------------=
