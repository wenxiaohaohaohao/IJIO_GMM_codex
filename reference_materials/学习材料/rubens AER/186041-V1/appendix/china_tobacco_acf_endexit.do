/* 
===========================================================
GMM PRODUCTION FUNCTION ESTIMATION
===========================================================
*/

* Code based on De Loecker (AEJ: Micro, 2013)

set more off
cd "$station" 

*use data_pf, clear

/*********** Optimization by Mata****************/
set more off
mata:
mata clear
//OLS estimates used for initial values
	X_main=st_data(., ("const", "l", "k", " p" , " uw"  ))
	X=(X_main)
	Y=st_data(., ("y"))
	beta_init = invsym(X'X)*X'Y
	beta_init = beta_init'
	st_matrix("beta_init", beta_init)

	// bringing data from stata; st_view() may be better 
	PHI=st_data(., ("phi")) 
	SURV=st_data(.,("px"))
	PHI_lag=st_data(.,("phi_lag"))
	PX_lag=st_data(., ("px_lag")) 
	CONSOL=st_data(., ("treat02_dq6","treat_dq6","post02")) 
	Z_main=st_data(., ("const" ,"l_lag", "k" , "k_lag"   , "p",  "p_lag",  "uw"  ))
    X_main_lag=st_data(., ("const" ,"l_lag", "k_lag" , " p_lag" , " uw_lag"    ))
    
	X=X_main
	X_lag=X_main_lag
	Z=Z_main
	Y=st_data(., ("y"))
	C=st_data(., ("const"))	
	
/* De Loecker method - Endogenous Productivity Change*/
// defining GMM_DL_linear function
void GMM_DL_linear(todo, betas, crit, g, H)
{
	external PHI,PHI_lag,Z_main,X_main,X_main_lag,X,X_lag,Z,Y,C	,SURV, PX_lag, CONSOL
		
    // create variables to polynomial approximation of g function
	// this time, a set of the variables should include LB, EA, LA
	OMEGA = PHI - X*betas'
	OMEGA_lag = PHI_lag - X_lag*betas'
	OMEGA_lag2 = OMEGA_lag :* OMEGA_lag
	OMEGA_lag3 = OMEGA_lag2 :* OMEGA_lag
	OMEGA_lag_pool = (C, OMEGA_lag,SURV,CONSOL)

	// estimation of g() function 
	g_b = invsym(OMEGA_lag_pool'OMEGA_lag_pool)*OMEGA_lag_pool'OMEGA
	// residual function for GMM
	XI = OMEGA - OMEGA_lag_pool * g_b  
	// moment condition is Z'XI
	crit = (Z'XI)'(Z'XI)
} 

S = optimize_init()
optimize_init_evaluator(S, &GMM_DL_linear())
optimize_init_evaluatortype(S, "d0")
optimize_init_technique(S, "nm")
optimize_init_nmsimplexdeltas(S, 0.1)
optimize_init_which(S, "min")
optimize_init_params(S, beta_init)
beta_dl_linear = optimize(S)
j_dl_linear = optimize_result_value(S)
st_matrix("beta_lin", beta_dl_linear')
st_matrix("beta_ols",beta_init)

// standard errors
gmm_V=(1/(rows(X)-cols(X)))*(Y-X*beta_dl_linear')'*(Y-X*beta_dl_linear')*invsym(X'*X)
gmm_se = (sqrt(diagonal(gmm_V)))
st_matrix("beta_lin_se", gmm_se)
end

matrix list beta_lin	// 
matrix list beta_lin_se	// still need to bootstrap these

exit

** R^2






