from pathlib import Path

p = Path(r"1017/1022_non_hicks/code/estimate/bootstrap1229_group.do")
text = p.read_text(encoding="utf-8", newline="")

elastic_block = '''* ---- 5.3 Elasticity diagnostics from point estimates ---- *
capture drop theta_k_hat theta_l_hat theta_m_hat
gen double theta_k_hat = `b_k_hat' + 2*`b_ksq_hat'*k
gen double theta_l_hat = `b_l_hat' + 2*`b_lsq_hat'*l
gen double theta_m_hat = `b_m_hat'

qui summarize theta_k_hat, meanonly
local elas_k_mean = r(mean)
qui summarize theta_l_hat, meanonly
local elas_l_mean = r(mean)
qui summarize theta_m_hat, meanonly
local elas_m_mean = r(mean)

qui count
local N_elas = r(N)
qui count if theta_k_hat < 0
local elas_k_negshare = cond(`N_elas'>0, r(N)/`N_elas', .)
qui count if theta_l_hat < 0
local elas_l_negshare = cond(`N_elas'>0, r(N)/`N_elas', .)
qui count if theta_m_hat < 0
local elas_m_negshare = cond(`N_elas'>0, r(N)/`N_elas', .)

di as txt "Elasticity means: theta_K=" %9.5f `elas_k_mean' "  theta_L=" %9.5f `elas_l_mean' "  theta_M=" %9.5f `elas_m_mean'
di as txt "Elasticity negative shares: theta_K=" %6.3f `elas_k_negshare' "  theta_L=" %6.3f `elas_l_negshare' "  theta_M=" %6.3f `elas_m_negshare'

preserve
    keep firmid year cic2 theta_k_hat theta_l_hat theta_m_hat
    gen str10 group = "`GROUPNAME'"
    order group firmid year cic2 theta_k_hat theta_l_hat theta_m_hat
    compress
    save "$DATA_WORK/elasticity_group_`GROUPNAME'.dta", replace
restore

* ---- 5.4 firm-level omega_hat / xi_hat output ---- *
'''

needle = 'capture drop omega_hat xi_hat'
if needle in text and elastic_block not in text:
    text = text.replace(needle, elastic_block + needle, 1)

old_point = '''    gen b_const = b[1,1]
    gen b_l     = b[2,1]
    gen b_k     = b[3,1]
    gen b_lsq   = b[4,1]
    gen b_ksq   = b[5,1]
    gen b_m     = b[6,1]
    gen b_es    = b[7,1]
    gen b_essq  = b[8,1]
'''
new_point = '''    gen b_const = `b_const_hat'
    gen b_l     = `b_l_hat'
    gen b_k     = `b_k_hat'
    gen b_lsq   = `b_lsq_hat'
    gen b_ksq   = `b_ksq_hat'
    gen b_m     = `b_m_hat'
    gen b_amc   = `b_amc_hat'
    gen b_as    = `b_as_hat'
    * Backward-compatible aliases
    gen b_es    = b_amc
    gen b_essq  = b_as
'''
if old_point in text:
    text = text.replace(old_point, new_point, 1)

old_after = '''    gen b_firmcat_2 = `b_firmcat2_hat'
    gen b_firmcat_3 = `b_firmcat3_hat'
'''
new_after = '''    gen b_firmcat_2 = `b_firmcat2_hat'
    gen b_firmcat_3 = `b_firmcat3_hat'
    gen elas_k_mean = `elas_k_mean'
    gen elas_l_mean = `elas_l_mean'
    gen elas_m_mean = `elas_m_mean'
    gen elas_k_negshare = `elas_k_negshare'
    gen elas_l_negshare = `elas_l_negshare'
    gen elas_m_negshare = `elas_m_negshare'
'''
if old_after in text:
    text = text.replace(old_after, new_after, 1)

old_order = '''    order group b_const b_l b_k b_lsq b_ksq b_m b_es b_essq ///
          b_c0_omega b_ar1_omega b_lnage b_firmcat_2 b_firmcat_3 ///
          J_unit J_opt J_df J_p N
'''
new_order = '''    order group b_const b_l b_k b_lsq b_ksq b_m b_amc b_as b_es b_essq ///
          b_c0_omega b_ar1_omega b_lnage b_firmcat_2 b_firmcat_3 ///
          elas_k_mean elas_l_mean elas_m_mean elas_k_negshare elas_l_negshare elas_m_negshare ///
          J_unit J_opt J_df J_p N
'''
if old_order in text:
    text = text.replace(old_order, new_order, 1)

p.write_text(text, encoding='utf-8', newline='')
print('OK')
