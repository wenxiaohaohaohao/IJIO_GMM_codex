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
