cd "$station" 
******************** First Stage Estimation *********************
/*Create second and third order terms for polynomial approximation*/
set matsize 11000

*use ./tempfiles/data_pf, clear
set more off
keep y p l k uw    typeid dhs2 treat* post02 yr fid const  dexp pctexp L  K     Q P   UW qshare_dq2  qshare_dq6 qshare_nest_dq6  pm  px dq2id px_lag

 

sum y p l k uw

set more off
local M = 3
local N = 3
local O = 3
local P = 3
	forvalues m=0(1)`M'{
	forvalues n=0(1)`N'{
	forvalues o=0(1)`O'{
	forvalues p=0(1)`P'{
	gen l`m'k`n'p`o'uw`p'   = l^(`m')*k^(`n')*p^(`o')*uw^(`p') 
			}
		}
	}
}
 
 gen lpm = log(pm)

gen typeid1 = typeid==1
quietly{
reg y l* pm  qshare_dq6 qshare_nest_dq6 px qshare_dq2  treat_dq6 treat02_dq6 post02 
predict double phi if e(sample)==1 
gen phi_lag=L.phi if e(sample)==1
}

******************** Second Stage Estimation *********************
/* create lagged variables */
foreach var of varlist l k p uw treat02_dq6 treat_dq6 post02 qshare_dq2 {
gen `var'_lag = L.`var'
}
drop if l == .
drop if k == .
drop if y==.| l==.| k==.|L.l==. |L.k==.
drop if phi == .
drop if phi_lag == .
*drop if luw==. | luw_lag==.



