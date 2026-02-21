# Version A: Main Spec vs. Robustness (Not in Main Code)

## 1) Main specification in current `bootstrap1229_group.do`

- Dynamic law (Hicks-neutral productivity, second stage):
  - `omega_t = c0 + rho * omega_{t-1} + controls_t + xi_t`
- Estimation style:
  - Nonlinear production-side parameters are estimated by outer GMM optimization.
  - Linear dynamic-block parameters `(c0, rho, controls)` are concentrated out by OLS/QR **for each candidate nonlinear parameter vector**.

Code mapping:

- `OMEGA = PHI - X*b'` and `OMEGA_lag = PHI_lag - X_lag*b'`
- `POOL = (C, OMEGA_lag, CONSOL)`
- `gb = qrsolve(POOL, OMEGA)`
- `XI = OMEGA - POOL*gb`

This is AR(1)-style Markov dynamics with concentrating-out, and it is the **main** specification.

## 2) Why Version A is kept as main

- Fewer dynamic parameters and lower variance under limited IV strength.
- Better numerical stability in your current data environment.
- Clearer baseline for later robustness and migration.

## 3) V1 linked constraint & diagnostics (new additions)

- `bootstrap1229_group.do` now exposes `RUN_POINT_ONLY`, `RUN_BOOT`, `RUN_DIAG`, and an `IV_SET` (A/B/C) switch so you can run point estimation, selective bootstrap, and compare IV sets without rerunning the whole pipeline (`RUN_SWITCH` debug print near the top).  
- In preprocessing we keep `r_hat_ols` as `shat` and 1-period lagged `shat_lag` to recreate Hicks-neutral productivity enough times inside Mata; they are fed to `refresh_globals()` to expose `S` updates to the nonlinear objective (`X` only holds the linear block for initialization).  
- The Mata evaluator now enforces the structural constraint: `amc = exp(raw_amc)` guarantees α_M>0, `S = 1 - exp(-shat)/amc` and `S_lag` are recomputed every iteration, and any S outside (0,1) or invalid `amc` penalizes the objective to keep solutions in the economics region.  
- `b_amc` (exp(raw)) and `b_as` replace the old `b_es/b_essq` as the nonlinear parameters; the old names are kept as aliases so downstream scripts (`Master_Non_hicks.do`) keep working.  
- After point estimation we calculate firm-level elasticity diagnostics (`theta_k/l/m`), print their means & negative shares, and save `elasticity_group_<GROUP>.dta`.
- The optional diagnostic module now runs ivreg2 for `IV_SET` A/B/C, records convergence/J statistics per set, and writes `$DATA_WORK/iv_diag_group_<GROUP>.dta` (with `pass_j` flag) so you can choose IV combinations by strict criteria.

## 3) Robustness specification (do not put into main flow now)

Planned robustness:

- Replace AR(1)-style linear `g(omega_{t-1})` with cubic polynomial:
  - `omega_t = c0 + rho1*omega_{t-1} + rho2*omega_{t-1}^2 + rho3*omega_{t-1}^3 + controls_t + xi_t`

Minimal code-level idea (future):

- In Mata dynamic block, expand:
  - from `POOL = (C, OMEGA_lag, CONSOL)`
  - to   `POOL = (C, OMEGA_lag, OMEGA_lag:^2, OMEGA_lag:^3, CONSOL)`
- Keep the same concentrating-out logic (`qrsolve`) and the same GMM objective.

This robustness version should be implemented in a separate script, not in `bootstrap1229_group.do`.

## 4) Paper-ready wording (English)

Main specification paragraph:

"In the second stage, we model Hicks-neutral productivity using an AR(1)-style law of motion. For each candidate vector of nonlinear production parameters, we recover the linear coefficients in the productivity transition equation (intercept, lagged productivity loading, and controls) by concentrating out via linear projection. The resulting innovation enters the GMM moment conditions, so nonlinear and linear blocks are estimated jointly in the objective, while preserving numerical stability."

Robustness paragraph:

"As a robustness check, we replace the linear AR(1)-style transition with a cubic polynomial in lagged productivity, following a more flexible first-order Markov approximation. This robustness is implemented in a separate specification and is not used in the baseline estimates."
