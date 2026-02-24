clear all
set more off
use "data/work/run_20260224_041356/firststage.dta", clear
xtset firmid year
capture confirm variable shat_lag
if _rc gen double shat_lag = L.shat

gen double e_now = exp(-shat)
gen double e_lag = exp(-shat_lag)
gen byte okpair = !missing(e_now,e_lag)

qui su shat if okpair, meanonly
scalar shbar = r(mean)
scalar amc0 = exp(-shbar) + 0.10

gen double S0_now = 1 - e_now/amc0 if okpair
gen double S0_lag = 1 - e_lag/amc0 if okpair

qui su e_now if okpair, meanonly
scalar max_e_now = r(max)
scalar min_e_now = r(min)
qui su e_lag if okpair, meanonly
scalar max_e_lag = r(max)
scalar min_e_lag = r(min)
scalar lb_amc = max(max_e_now,max_e_lag)
scalar ub_amc = min(min_e_now,min_e_lag)/1e-8

qui count if okpair
noi di "N_okpair=" r(N)
noi di "shbar=" %12.6f shbar
noi di "amc0=" %12.6f amc0
noi di "LB_amc=" %12.6f lb_amc
noi di "UB_amc=" %12.6f ub_amc

qui su S0_now if okpair, meanonly
noi di "S0_now_min=" %12.6f r(min)
noi di "S0_now_max=" %12.6f r(max)
qui count if okpair & (S0_now<=1e-8 | S0_now>=1-1e-8)
noi di "S0_now_outcount=" r(N)

qui su S0_lag if okpair, meanonly
noi di "S0_lag_min=" %12.6f r(min)
noi di "S0_lag_max=" %12.6f r(max)
qui count if okpair & (S0_lag<=1e-8 | S0_lag>=1-1e-8)
noi di "S0_lag_outcount=" r(N)

scalar amc_lb = lb_amc*1.000001
gen double S_lb_now = 1 - e_now/amc_lb if okpair
gen double S_lb_lag = 1 - e_lag/amc_lb if okpair
qui su S_lb_now if okpair, meanonly
noi di "S_lb_now_min=" %12.6f r(min)
noi di "S_lb_now_max=" %12.6f r(max)
qui su S_lb_lag if okpair, meanonly
noi di "S_lb_lag_min=" %12.6f r(min)
noi di "S_lb_lag_max=" %12.6f r(max)
