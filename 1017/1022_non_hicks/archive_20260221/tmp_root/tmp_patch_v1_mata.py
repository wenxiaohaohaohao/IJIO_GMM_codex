import re
from pathlib import Path

p = Path(r"1017/1022_non_hicks/code/estimate/bootstrap1229_group.do")
text = p.read_text(encoding="utf-8", newline="")

new_refresh = '''void refresh_globals()
{
    external X, X_lag, Z, PHI, PHI_lag, Y, C, CONSOL, beta_init, Wg_opt
    external LVAR, KVAR, LSQVAR, KSQVAR, MVAR, LLAGVAR, KLAGVAR, LSQLAGVAR, KSQLAGVAR, MLAGVAR, SHAT, SHAT_lag

    /* V1 linked-constraint setup: X only for initialization; S is updated inside evaluator */
    X       = st_data(., ("const","l","k","lsq","ksq","m"))
    X_lag   = st_data(., ("const","llag","klag","lsqlag","ksqlag","mlag"))

    LVAR    = st_data(., "l")
    KVAR    = st_data(., "k")
    LSQVAR  = st_data(., "lsq")
    KSQVAR  = st_data(., "ksq")
    MVAR    = st_data(., "m")
    LLAGVAR   = st_data(., "llag")
    KLAGVAR   = st_data(., "klag")
    LSQLAGVAR = st_data(., "lsqlag")
    KSQLAGVAR = st_data(., "ksqlag")
    MLAGVAR   = st_data(., "mlag")
    SHAT      = st_data(., "shat")
    SHAT_lag  = st_data(., "shat_lag")

    /* IV sets by group and IV_SET switch */
    string scalar g, ivset
    g = st_global("GROUP_NAME")
    ivset = st_global("IV_SET")
    if (ivset=="") ivset = "A"
    if (g!="G1_17_19" & g!="G2_39_41") {
        errprintf("Invalid GROUPNAME = [%s]; must be G1_17_19 or G2_39_41\\n", g)
        _error(3499)
    }
    if (ivset!="A" & ivset!="B" & ivset!="C") {
        errprintf("Invalid IV_SET = [%s]; must be A/B/C\\n", ivset)
        _error(3499)
    }

    if (g=="G1_17_19" & ivset=="A") {
        Z = st_data(., ("const","lages2q","l","ksq","llag","klag","mlag","l_ind_yr","m_ind_yr","k_ind_yr","Z_HHI_post"))
    }
    else if (g=="G1_17_19" & ivset=="B") {
        Z = st_data(., ("const","lages2q","l","lsq","ksq","llag","klag","mlag","l_ind_yr","m_ind_yr","k_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G1_17_19" & ivset=="C") {
        Z = st_data(., ("const","llag","klag","mlag","lages","lages2q","l_ind_yr","m_ind_yr","k_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G2_39_41" & ivset=="A") {
        Z = st_data(., ("llag","klag","l","lages","lsq","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else if (g=="G2_39_41" & ivset=="B") {
        Z = st_data(., ("const","llag","klag","mlag","l","lsq","ksq","l_ind_yr","k_ind_yr","m_ind_yr","Z_tariff","Z_HHI_post"))
    }
    else {
        Z = st_data(., ("const","llag","klag","mlag","lages","lages2q","l_ind_yr","k_ind_yr","m_ind_yr","Z_HHI_post"))
    }

    PHI     = st_data(., "phi")
    PHI_lag = st_data(., "phi_lag")
    Y       = st_data(., "r")
    C       = st_data(., "const")

    CONSOL  = st_data(., ("dy2002","dy2003","dy2004","dy2005","dy2006","dy2007","lnage","firmcat_2","firmcat_3"))

    real scalar use_b0, shbar, amc0, raw_amc0
    real rowvector bols
    use_b0 = strtoreal(st_local("have_b0"))

    if (rows(X) != rows(Y)) {
        errprintf(">>> ERROR: rows(X) != rows(Y) in qrsolve\\n")
        _error(3497)
    }
    if (cols(Y) != 1) {
        errprintf(">>> ERROR: Y is not a column vector in qrsolve\\n")
        _error(3497)
    }
    if (any(missing(X)) | any(missing(Y)) | any(missing(SHAT)) | any(missing(SHAT_lag))) {
        errprintf(">>> ERROR: Missing values in core data before optimization\\n")
        _error(3497)
    }

    bols = qrsolve(X, Y)'
    shbar = mean(SHAT)
    if (missing(shbar)) shbar = 0
    amc0 = exp(-shbar) + 0.10
    raw_amc0 = ln(amc0)

    if (use_b0 == 1) {
        beta_init = st_matrix("b0")'
        if (cols(beta_init) != 8) {
            beta_init = (bols, raw_amc0, 0)
        }
    }
    else {
        beta_init = (bols, raw_amc0, 0)
    }
}'''

new_gmm = '''void GMM_DL_weighted(todo, b, crit, g, H)
{
    external PHI, PHI_lag, Z, C, CONSOL, Wg, Wg_opt
    external LVAR, KVAR, LSQVAR, KSQVAR, MVAR, LLAGVAR, KLAGVAR, LSQLAGVAR, KSQLAGVAR, MLAGVAR, SHAT, SHAT_lag

    real colvector OMEGA, OMEGA_lag, XI, gb, m, S_now, S_lag
    real matrix POOL
    real scalar N, crit_val, amc, smin_now, smax_now, smin_lag, smax_lag

    N = rows(Z)
    if (N <= 5 | any(missing(Z))) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    if (rows(Wg_opt)==0 | cols(Wg_opt)==0 | rows(Wg_opt)!=cols(Z) | cols(Wg_opt)!=cols(Z)) {
        Wg_opt = I(cols(Z))
    }

    /* V1 linked-constraint:
       amc = exp(raw_amc) guarantees positivity;
       S and S_lag are updated at each iteration using shat/shat_lag. */
    amc = exp(b[7])
    if (missing(amc) | amc<=1e-8 | amc>1e+8) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    S_now = 1 :- exp(-SHAT) :/ amc
    S_lag = 1 :- exp(-SHAT_lag) :/ amc
    smin_now = min(S_now); smax_now = max(S_now)
    smin_lag = min(S_lag); smax_lag = max(S_lag)
    if (any(missing(S_now)) | any(missing(S_lag)) | smin_now<=1e-8 | smax_now>=1-1e-8 | smin_lag<=1e-8 | smax_lag>=1-1e-8) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    OMEGA = PHI :- (b[1] :+ b[2]:*LVAR :+ b[3]:*KVAR :+ b[4]:*LSQVAR :+ b[5]:*KSQVAR :+ b[6]:*MVAR :+ b[8]:*(S_now:^2))
    OMEGA_lag = PHI_lag :- (b[1] :+ b[2]:*LLAGVAR :+ b[3]:*KLAGVAR :+ b[4]:*LSQLAGVAR :+ b[5]:*KSQLAGVAR :+ b[6]:*MLAGVAR :+ b[8]:*(S_lag:^2))

    if (cols(CONSOL)>0) POOL = (C, OMEGA_lag, CONSOL)
    else                POOL = (C, OMEGA_lag)

    gb  = qrsolve(POOL, OMEGA)
    XI  = OMEGA - POOL * gb

    N       = rows(Z)
    m       = quadcross(Z, XI) :/ N
    crit_val = m' * Wg_opt * m

    if (missing(crit_val) | crit_val>1e+30 | crit_val<-1e+30) {
        crit = 1e+20
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    if (crit_val < 1e-10 * N) {
        crit = crit_val
        if (todo >= 1) g = J(1, cols(b), 0)
        if (todo == 2) H = J(cols(b), cols(b), 0)
        return
    }

    crit = crit_val

    if (todo>=1) {
        real scalar i, eps_i, crit_plus, crit_minus
        real rowvector gnum, btmp
        real colvector Oe, Oel, XI2p, XI2m, m2p, m2m, Sp, Slp, Sm, Slm
        real matrix PO

        gnum = J(1, cols(b), .)

        for (i=1; i<=cols(b); i++) {
            eps_i = scalarmax(1e-6, 1e-6 * abs(b[i]))

            btmp    = b
            btmp[i] = b[i] + eps_i
            amc = exp(btmp[7])
            if (missing(amc) | amc<=1e-8 | amc>1e+8) {
                crit_plus = 1e+20
            }
            else {
                Sp = 1 :- exp(-SHAT) :/ amc
                Slp = 1 :- exp(-SHAT_lag) :/ amc
                if (any(missing(Sp)) | any(missing(Slp)) | min(Sp)<=1e-8 | max(Sp)>=1-1e-8 | min(Slp)<=1e-8 | max(Slp)>=1-1e-8) {
                    crit_plus = 1e+20
                }
                else {
                    Oe = PHI :- (btmp[1] :+ btmp[2]:*LVAR :+ btmp[3]:*KVAR :+ btmp[4]:*LSQVAR :+ btmp[5]:*KSQVAR :+ btmp[6]:*MVAR :+ btmp[8]:*(Sp:^2))
                    Oel = PHI_lag :- (btmp[1] :+ btmp[2]:*LLAGVAR :+ btmp[3]:*KLAGVAR :+ btmp[4]:*LSQLAGVAR :+ btmp[5]:*KSQLAGVAR :+ btmp[6]:*MLAGVAR :+ btmp[8]:*(Slp:^2))
                    PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
                    gb  = qrsolve(PO, Oe)
                    XI2p = Oe - PO*gb
                    m2p  = quadcross(Z, XI2p):/ N
                    crit_plus = m2p' * Wg_opt * m2p
                }
            }

            btmp    = b
            btmp[i] = b[i] - eps_i
            amc = exp(btmp[7])
            if (missing(amc) | amc<=1e-8 | amc>1e+8) {
                crit_minus = 1e+20
            }
            else {
                Sm = 1 :- exp(-SHAT) :/ amc
                Slm = 1 :- exp(-SHAT_lag) :/ amc
                if (any(missing(Sm)) | any(missing(Slm)) | min(Sm)<=1e-8 | max(Sm)>=1-1e-8 | min(Slm)<=1e-8 | max(Slm)>=1-1e-8) {
                    crit_minus = 1e+20
                }
                else {
                    Oe = PHI :- (btmp[1] :+ btmp[2]:*LVAR :+ btmp[3]:*KVAR :+ btmp[4]:*LSQVAR :+ btmp[5]:*KSQVAR :+ btmp[6]:*MVAR :+ btmp[8]:*(Sm:^2))
                    Oel = PHI_lag :- (btmp[1] :+ btmp[2]:*LLAGVAR :+ btmp[3]:*KLAGVAR :+ btmp[4]:*LSQLAGVAR :+ btmp[5]:*KSQLAGVAR :+ btmp[6]:*MLAGVAR :+ btmp[8]:*(Slm:^2))
                    PO  = (cols(CONSOL)>0 ? (C, Oel, CONSOL) : (C, Oel))
                    gb  = qrsolve(PO, Oe)
                    XI2m = Oe - PO*gb
                    m2m  = quadcross(Z, XI2m):/ N
                    crit_minus = m2m' * Wg_opt * m2m
                }
            }

            if (missing(crit_plus) | missing(crit_minus)) {
                gnum[i] = 0
            }
            else {
                gnum[i] = (crit_plus - crit_minus) / (2*eps_i)
            }
        }

        g = gnum
    }
}'''

pat1 = re.compile(r'void refresh_globals\(\)\s*\{.*?\n\}\n\nvoid GMM_DL_weighted\(todo, b, crit, g, H\)', re.S)
if not pat1.search(text):
    raise SystemExit('PAT1_NOT_FOUND')
text = pat1.sub(new_refresh + "\n\nvoid GMM_DL_weighted(todo, b, crit, g, H)", text, count=1)

pat2 = re.compile(r'void GMM_DL_weighted\(todo, b, crit, g, H\)\s*\{.*?\n\}\n\nvoid run_two_step\(\)', re.S)
if not pat2.search(text):
    raise SystemExit('PAT2_NOT_FOUND')
text = pat2.sub(new_gmm + "\n\nvoid run_two_step()", text, count=1)

p.write_text(text, encoding='utf-8', newline='')
print('OK')
