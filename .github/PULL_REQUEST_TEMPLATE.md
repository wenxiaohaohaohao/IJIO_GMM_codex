# Pull Request Template

## 1. Objective
- What research question / code issue does this PR address?
- Link issue(s): #

## 2. Scope of Changes
- Files changed:
- Model layer changed: `yes/no`
- Data pipeline changed: `yes/no`
- Output path changed: `yes/no`

## 3. Econometric Impact
- Estimation system affected (equation IDs):
- Linear parameters affected:
- Nonlinear parameters affected:
- Identification / IV set changed:

## 4. Reproducibility
- Command(s) used:
- Sample / group(s):
- Random seed(s):
- Key output files generated:

## 5. Results Snapshot (before vs after)
- Convergence (`gmm_conv`):
- `J_opt`, `J_p`:
- Key elasticity means (`theta_k`, `theta_l`, `theta_m`):
- Negative-share diagnostics:

## 6. Risk Check
- Potential regression risk:
- Backward compatibility preserved: `yes/no`
- Need rollback plan: `yes/no`

## 7. Checklist
- [ ] I ran point estimation (`RUN_POINT_ONLY=1`) and checked logs.
- [ ] I verified output file locations are correct.
- [ ] I compared at least one baseline run.
- [ ] I documented changes in workflow notes / issue.
- [ ] No data file (`.dta/.zip`) was modified unintentionally.
