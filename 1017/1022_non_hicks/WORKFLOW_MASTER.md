# 1022_non_hicks Workflow Master

Last update: 2026-02-21

## Path Lock (Mandatory)

- Canonical workspace root (the only valid root for this project phase):
  - `D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks`
- Do not use old root or backup/archive folders as active code references.
- All run/read/write operations must target the canonical root above.

## 1. 唯一主代码（当前生效）

- `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do`
- `1017/1022_non_hicks/code/master/Master_Non_hicks.do`
- `1017/1022_non_hicks/code/master/run_group_G1.do`
- `1017/1022_non_hicks/code/master/run_group_G2.do`

除上述 4 个文件外，其余版本均视为历史归档，不参与当前主流程。

## 2. 当前估计系统（硬联立）

- 约束参数重参数化：`amc = exp(raw_amc)`，保证 `amc > 0`。
- 迭代内更新份额约束：
  - `S_now = 1 - exp(-shat)/amc`
  - `S_lag = 1 - exp(-shat_lag)/amc`
- 主方程（非线性块）：
  - `Omega = Phi - (b0 + bl*l + bk*k + bll*l^2 + bkk*k^2 + bm*m + bas*S^2)`
- 转移方程（线性块 concentrated-out）：
  - `Omega = c0 + rho*Omega_lag + controls + xi`
  - 线性块每次迭代用 `qrsolve` 浓缩。
- 目标函数：两步 GMM，`m' W m`。

## 3. 参数命名策略（当前阶段）

- 当前保持兼容别名并存：
  - 新命名：`b_amc`, `b_as`
  - 兼容别名：`b_es`, `b_essq`
- 注意：在硬联立版本中
  - `b_es` 实际对应 `b_amc`
  - `b_essq` 实际对应 `b_as`

## 4. 运行入口与模式

- 主入口：`Master_Non_hicks.do`
- 分组入口：`run_group_G1.do`, `run_group_G2.do`
- 关键开关：
  - `RUN_POINT_ONLY=1`：只跑点估，不跑 bootstrap
  - `RUN_BOOT=1`：跑 bootstrap
  - `RUN_DIAG=1`：开启诊断
  - `IV_SET=A/B/C`：IV 集合切换

## 5. 回退与归档

- 历史文件归档目录：
  - `1017/1022_non_hicks/code/archive_20260221/estimate/`
  - `1017/1022_non_hicks/code/archive_20260221/master/`
- 本项目文档归档目录：
  - `1017/1022_non_hicks/archive_20260221/md/`

如需回退，优先从以上 archive 目录恢复对应版本。

## 6. 未来一次性改名计划（暂不执行）

在“所有项目修改结束”后，再执行一次性彻底改名：

1. 主代码和 master 全部改为仅使用 `b_amc/b_as`。
2. 输出文件移除 `b_es/b_essq` 别名字段。
3. 同步更新文稿/表格口径。
4. 执行前先打最终锁定备份。

当前阶段不执行上述彻底改名，只维持兼容方案以保证流程稳定。


## 7. History Notes (Background Only, Not Executable)

以下内容仅用于历史追溯与口径说明，不作为任何运行入口、参数设置或代码修改指令。

- 2026-02-08 静态检查结论：主流程 active path 的路径问题已做过一次清理；历史文件中仍可能存在 fallback 绝对路径，运行时以第 1 节主代码为准。
- 2026-02-15 到 2026-02-16 曾并行存在两条估计分支：
  - rollback_before_V1linked：非硬联立（es/es2q 外生化）
  - V1_linked：硬联立约束（S 在迭代内更新）
  当前主代码已锁定为硬联立分支。
- 2026-02-19 到 2026-02-21 进行过运行层与目录层清理：
  - 运行层：点估/诊断批处理流程验证
  - 目录层：仅保留主代码文件，其余历史代码与临时文件已归档
- 命名策略阶段性约定：当前保留兼容别名（b_amc/b_as 与 b_es/b_essq 并存）；全部项目修改结束后再做一次性“彻底修正命名版本”。

Historical source files are archived under:
- `1017/1022_non_hicks/archive_20260221/md/`

## 8. M0 Pre-Stage (Mandatory Before R0-R3)

Goal:
- Validate and lock the intermediate-input (`m`) construction chain before any further IV expansion.
- Main-definition baseline must follow active main code exactly; Yinheng-style construction is robustness only.

### 8.1 Scope freeze (no execution expansion)
1. Keep hard-linked structural system unchanged.
2. Keep IV set fixed during M0 diagnosis.
3. Use point+diag only (`RUN_POINT_ONLY=1`, `RUN_BOOT=0`, `RUN_DIAG=1`).

### 8.2 Main-code-aligned `m` chain lock (baseline A)
1. Trace `m` from raw variable -> deflation -> cleaning -> log transform -> stage-2 entry.
2. Build a mapping table with variable name, economic meaning, unit, transform, and code location.
3. Baseline A is always active-main-code definition (no external overwrite).

### 8.3 Stage-1 / Stage-2 compatibility audit (core)
What to verify:
1. Whether stage-1 generated regressors (`phi/shat/es`) are built from the same intermediate-input definition used by stage-2 `m`.
2. Whether stage-1 and stage-2 samples are identical, or differences are fully traceable and economically explainable.
3. If generated-regressor mismatch symptoms appear, repair stage-1 definition/sampling first, then re-estimate.

Econometric meaning:
- In control-function GMM, stage-1 objects are generated regressors. If their input definition differs from stage-2 `m` (unit/deflation/sample rules), moments become structurally misaligned even if algebra still runs.
- This typically causes unstable `b_m`, extreme `J/J_p`, and high sensitivity to IV switching.
- Therefore, compatibility correction has priority over adding more IVs.

Operational checks:
1. Definition consistency table (stage-1 vs stage-2): unit, deflator base, positivity rule, winsor/drop rule.
2. Sample-difference decomposition: intersection and exclusions by cause.
3. Fixed-IV comparison under (i) current sample and (ii) aligned sample only.

### 8.4 M0 sensitivity design (A/B/C)
1. A (Main): current active-code intermediate-input construction.
2. B: cleaning-threshold robustness (winsor/trimming variant), all else fixed.
3. C: Yinheng-style intermediate-input construction as alternative robustness branch.
4. No separate "alternative deflator" branch in M0.

### 8.5 M0 hard gates (must pass before R0-R3)
1. `gmm_conv == 1`.
2. `b_m` in main spec within `[0.7, 0.9]`.
3. `J_p` not persistently extreme.
4. Capital/labor total elasticities not systematically implausible.
5. A/B/C comparison shows no unexplained jump in `b_m`.

### 8.6 M0 deliverables
1. Main vs Yinheng intermediate-input mapping table.
2. Stage-1/Stage-2 sample-difference table.
3. A/B/C result table (`b_m`, `J_p`, convergence, elasticity sign diagnostics).
4. Short method note: why M0 precedes IV expansion.

## 9. Research Roadmap R0-R3 (Frozen)

Use the following stage framework as the controlling plan:

- R0: Main-spec baseline
- R1: IV screening within the main specification
- R2: Switch to ACF/RDP-style IV design
- R3: Robustness consolidation and reporting

This R0-R3 definition is the project-level roadmap standard and overrides older wording in prior notes.

## 10. Appendix-Ready English Method Note (IV Logic, Aligned with R0-R3)

### A. Why add R2 (ACF/RDP-style IV robustness)

Our baseline estimation uses a two-step GMM framework with a control-function structure and concentrating-out for the linear productivity-transition block. In this setting, identification quality depends not only on instrument relevance in a generic linear-IV sense, but also on whether instruments are aligned with the model's information structure (predetermined states and lagged observables entering the control-function recursion). Therefore, after baseline and in-spec IV screening (R0/R1), we add a dedicated robustness layer (R2) that constructs instruments following the Yinheng/RDP-style logic: lagged state variables and low-order polynomial terms consistent with the timing assumptions used by the control-function/concentrating-out system.

### B. Econometric rationale

The rationale is threefold. First, under control-function identification, valid instruments should be measurable with respect to the firm's information set prior to current-period shocks, so lagged states and their polynomial transformations are natural candidates. Second, concentrating-out reduces dimensionality by partialling out linear transition parameters at each candidate nonlinear vector, which makes the nonlinear moments highly sensitive to instrument geometry; structure-matched instruments can improve numerical conditioning and reduce weak-identification symptoms. Third, comparing baseline IVs with structure-matched IVs provides an internal cross-validation of identification assumptions: if key parameters keep their sign and order of magnitude while diagnostics improve, results are less likely to be driven by ad hoc instrument choice.

### C. Implementation and decision rule (R0 -> R1 -> R2 -> R3)

We do not replace the baseline specification mechanically. Instead, we run R0 as the main baseline, complete R1 IV screening within the main specification, and then run R2 as a robustness layer. We compare (i) convergence behavior, (ii) over-identification diagnostics, and (iii) elasticity plausibility (including negative-share frequencies). The baseline is retained as the main specification unless the structure-matched set simultaneously improves diagnostics and preserves economically coherent parameter patterns. This design separates "model structure validation" from "specification replacement," and keeps the empirical narrative transparent.

## 11. Temp Files Audit (Root)

Audit date: 2026-02-23

- Scope: root-level `tmp_*` files in the repository root.
- Conclusion: these files are not dependencies of the active run chain.
- Active run chain remains:
  - `1017/1022_non_hicks/code/master/Master_Non_hicks.do`
  - `1017/1022_non_hicks/code/master/run_group_G1.do`
  - `1017/1022_non_hicks/code/master/run_group_G2.do`
  - `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do`

Moved (archive only, not deleted) to:
- `1017/1022_non_hicks/archive_20260221/tmp_root/`

Moved file list:
- `tmp_getshort.bat`
- `tmp_getshort2.bat`
- `tmp_patch_v1_diag.py`
- `tmp_patch_v1_mata.py`
- `tmp_patch_v1_output.py`
- `tmp_run_point_g1.log`
- `tmp_run_point_g1g2.log`
- `tmp_run_point_g2.log`
- `tmp_run_point_g2_debug.log`
- `tmp_run_v1_point.do`
- `tmp_run_v1_point.log`
- `tmp_run_v1_point_batch.do`
- `tmp_run_v1_point_batch.log`
- `tmp_run_v1_point_only.log`
- `tmp_var_dict.docx`

Note:
- `tmp_run_v1_point.do` and `tmp_run_v1_point_batch.do` are optional manual launchers only; they are not called by the active master scripts.

## 12. Step 1 Log Read Policy (Execution Standard)

This section is mandatory for future Step 1 runs (`point + diagnostics`, no bootstrap).

### 11.1 Must-read logs

1. `1017/1022_non_hicks/results/logs/run_step1_point_diag.log`
2. `1017/1022_non_hicks/results/logs/main_twogroups_full_log_YYYYMMDD.log` (same run date, latest timestamp only)

Purpose:
- Confirm run mode flags are correct (`RUN_POINT_ONLY=1`, `RUN_BOOT=0`, `RUN_DIAG=1`)
- Confirm whether G1/G2 finished
- Capture first fatal error code and stage if failure occurs

### 11.2 Conditional logs (read only when must-read logs show errors)

1. `1017/1022_non_hicks/results/logs/tmp_point_run_driver.log`
2. `1017/1022_non_hicks/results/logs/tmp_point_G1G2_driver.log`
3. `1017/1022_non_hicks/results/logs/tmp_run_g2_point.log` (G2-only issue)
4. `1017/1022_non_hicks/results/logs/tmp_batch_v1_point.log` (batch-entry issue)

### 11.3 Explicit ignore list

1. `1017/1022_non_hicks/archive_20260221/tmp_root/*.log` (all historical)
2. Any log with `LastWriteTime < current run start time`
3. Old logs outside `results/logs`, including outdated root-level `main_twogroups_full_log_*.log`

### 11.4 Fixed screening rules

1. Record current run start timestamp before launching Stata.
2. Read only logs with `LastWriteTime >= run start timestamp`.
3. Always read must-read logs first.
4. Read conditional logs only if must-read logs indicate failure or inconsistency.
5. Do not use archive logs as evidence for current-run conclusions.

## 13. Hard-Constraint Reparameterization Note (2026-02-24)

Scope:
- Main edited file: `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do`
- Supporting run isolation already in:
  - `1017/1022_non_hicks/code/master/run_step1_point_diag.do`
  - `1017/1022_non_hicks/code/master/Master_Non_hicks.do`
  - `1017/1022_non_hicks/code/master/run_group_G1.do`
  - `1017/1022_non_hicks/code/master/run_group_G2.do`

### 12.1 Why the previous version failed

Observed error:
- `ERROR: S outside (0,1) in step 1.`

Mechanically, with
- `S_it = 1 - exp(-shat_it)/amc`
- `S_i,t-1 = 1 - exp(-shat_i,t-1)/amc`

the feasible support requires:
- `amc > max{exp(-shat_it), exp(-shat_i,t-1)}` for all observations used in moments.

The previous initialization (`amc0 = exp(-mean(shat)) + 0.10`) can be below this sample-implied lower bound, so the optimizer starts from an infeasible point and can repeatedly hit infeasible regions.

### 12.2 What was changed (estimation-equivalent transformation)

For the nonlinear parameter previously mapped as `amc = exp(raw_amc)`, we now use:

- `amc = amc_lb * (1 + amc_pad) + exp(raw_amc)`
- where `amc_lb = max(exp(-shat), exp(-shat_lag))` computed from current estimation sample
- and `amc_pad = 1e-6`

This was applied consistently in:
1. initialization (`raw_amc0`)
2. evaluator (`GMM_DL_weighted`)
3. step-1/step-2 feasibility checks (`run_two_step`)
4. returned point estimates (`b_amc`, alias `b_es`)

Interpretation:
- This is a reparameterization of the optimization coordinate, not a change in model equations or moment conditions.
- The hard-linked constraint is still exactly enforced.

### 12.3 Additional I/O safety edits (engineering only)

Because this machine blocks overwrite-in-place in some directories:
- point-only branch was adjusted to avoid unnecessary second `save, replace` of the same file in the same run.
- `firststage.dta` was renamed to group-specific files:
  - `firststage_G1_17_19.dta`
  - `firststage_G2_39_41.dta`

These edits do not change econometric identification or objective function.

### 12.4 Econometric rationale

1. Feasible-set enforcement:
- For share-like objects constrained to `(0,1)`, direct unconstrained search can spend iterations in economically impossible regions, causing non-smooth penalties and unstable convergence.
- Reparameterization imposes the support by construction.

2. Invariance of structural content:
- The moment function and concentrated-out linear block are unchanged.
- Only the coordinate map from unconstrained optimizer space to constrained structural parameter space is changed.

3. Numerical conditioning:
- Hard constraints reduce spurious optimizer failures caused by repeated boundary violations, especially in two-step GMM with nonlinear blocks and generated regressors.

### 12.5 Economic interpretation

## 14. R1 Execution Standard (C-clean Minimal Usable Set)

Scope:
- Keep model structure fixed (hard-linked system unchanged).
- In each run, change IV set only.
- Target: construct a stable `C-clean` minimal usable IV set before any higher-order expansion.

### 13.1 Fixed run controls (must hold)

1. `RUN_POINT_ONLY=1`
2. `RUN_BOOT=0`
3. `RUN_DIAG=1`
4. `TARGET_GROUP` tested separately for `G1_17_19` and `G2_39_41`

### 13.2 R1 loop procedure

1. Set baseline `IV_SET=C`.
2. Run baseline by group and record diagnostics.
3. Run leave-one-out on C instruments (drop one IV each run, per group).
4. Compare each candidate against baseline on the same group.
5. Keep candidates that pass all hard gates in 13.3.
6. Build `C-clean` as the smallest passing subset with best stability.
7. Freeze `C-clean` and only then enter R2 (ACF/RDP polynomial expansion).

### 13.3 Hard gates (pass/fail)

1. Convergence: `gmm_conv == 1`
2. Over-identification: `J_p` must move away from persistent near-zero boundary failures.
3. Elasticity plausibility: key elasticity signs/ranges must be economically coherent.
4. Stability: results should not jump materially across nearby initial values.
5. Feasibility: no repeated boundary/infeasible share violations.

Note:
- R1 objective is not one-shot optimum; objective is a robust minimal usable set.

### 13.4 Mandatory round record fields (for each run)

Use the exact fields below in run logs/tables:

1. `run_tag`
2. `group_name`
3. `iv_set`
4. `iv_variant`
5. `iv_dropped`
6. `n_obs`
7. `kz_used`
8. `gmm_conv`
9. `J_opt`
10. `J_df`
11. `J_p`
12. `b_k`
13. `b_l`
14. `b_m`
15. `b_amc`
16. `b_as`
17. `elas_k_mean`
18. `elas_l_mean`
19. `elas_m_mean`
20. `elas_k_neg_share`
21. `elas_l_neg_share`
22. `elas_m_neg_share`
23. `s_min`
24. `s_max`
25. `status` (`accept` / `robust_only` / `reject`)
26. `note`

### 13.5 Decision rule to finalize C-clean

1. First remove IVs that consistently worsen `J_p` and/or trigger instability.
2. Among surviving sets, prioritize low-dimension sets with stable signs/magnitudes.
3. Keep one final `C-clean` per group if necessary (`G1` and `G2` may differ).
4. Only after C-clean freeze, proceed to R2 layered ACF/RDP IV expansion (order 1 then 2).

## 15. Permission + Replace Runbook Entry

When `r(608)` appears (cannot modify/erase), use:

- `1017/1022_non_hicks/PERMISSION_REPLACE_RUNBOOK.md`

This runbook contains:
1. Script-based permission reset order
2. ACL fallback commands
3. Unified file-output overwrite policy (direct `replace`)

## 16. r(608) Postmortem (Must Remember)

### 15.1 Root cause from 2026-02-26

Observed mismatch:
- File attributes looked normal (`Archive`, not `ReadOnly`)
- File-level ACL looked permissive
- But `save ..., replace` still failed on root-level files (`firststage*.dta`)

Confirmed root cause:
- Directory-level ACL on `D:\paper\IJIO_GMM_codex_en` was insufficient for replace-style overwrite in Stata.
- Stata `replace` requires delete/overwrite capability at the directory level, not only file write permission.

### 15.2 Non-negotiable troubleshooting order

When any `r(608)` appears:
1. Check directory ACL first (target folder and parent folder).
2. Then check file ACL/attributes.
3. Run a root-level smoke test with `save ..., replace` on a temp file.
4. Only after smoke test passes, run the main estimation chain.

### 15.3 Permanent fix applied

Applied once:
- `icacls "D:\paper\IJIO_GMM_codex_en" /grant:r "WENXIAO\dongw:(OI)(CI)F" /T /C`

Validated:
- `firststage.dta`, `firststagecd.dta`, `firststagehicks.dta` all passed Stata `save ..., replace`.

### 15.4 Guardrail for future edits

Do not conclude "permissions are fine" from file readonly bits alone.
Always validate with an actual Stata replace smoke test before declaring the environment fixed.

## 17. PowerShell Quoting Postmortem (Must Remember)

### 16.1 Why this error kept happening

Root issue:
- We repeatedly mixed PowerShell string parsing with `cmd /c` parsing and Stata path quoting in one line.
- Nested quotes (`"..."` inside `"..."`) plus backslashes caused silent command mangling.
- As a result, the actual command passed to Stata was broken, leading to false diagnostics.

Typical symptoms:
1. `The string is missing the terminator: "` in PowerShell
2. `'\' is not recognized as an internal or external command` from `cmd`
3. Stata log not generated at expected location
4. Running old log by mistake and misreading run status

### 16.2 Hard rules (do not violate)

1. Do not use deeply nested inline one-liners for complex Stata launch commands.
2. Build command strings in steps:
   - normalize path
   - compose quoted command once
   - then execute
3. Prefer writing a temporary `.do` file and call Stata with absolute path to that file.
4. After each run, verify the specific log file timestamp before interpreting output.
5. If command composition is nontrivial, run a minimal ping do-file first.

### 16.3 Recommended launch pattern

Use this structure:

```powershell
$stata = "D:\\AppGallery\\stata18\\StataMP-64.exe"
$doAbs = "D:\\paper\\IJIO_GMM_codex_en\\...\\run_xxx.do"
$cmd = '"' + $stata + '" /e do "' + $doAbs + '"'
cmd /c $cmd
```

Avoid:
- direct nested quoting with mixed `'` and `"` in one long line
- using partially escaped backslashes inside interpolated PowerShell strings

### 16.4 Mandatory pre-run checks

Before batch runs:
1. `Test-Path` for Stata executable and target do-file
2. print composed `$cmd`
3. ensure output log path is absolute
4. clear stale temp launcher files if reused

### 16.5 Mandatory post-run checks

After run:
1. confirm expected log exists
2. confirm log `LastWriteTime` is current run time
3. read tail of current log only
4. do not reuse old logs as run evidence

- `S` is a constrained share object in the hard-linked system.
- `S<=0` or `S>=1` implies economically invalid allocation/probability interpretation.
- Enforcing support is therefore not cosmetic; it is part of structural coherence.

### 12.6 Literature anchors for write-up

Core GMM and implementation:
- Hansen (1982), *Large Sample Properties of Generalized Method of Moments Estimators*.

Control-function / production-function identification context:
- Olley and Pakes (1996), *The Dynamics of Productivity in the Telecommunications Equipment Industry*.
- Levinsohn and Petrin (2003), *Estimating Production Functions Using Inputs to Control for Unobservables*.
- Wooldridge (2009), *On Estimating Firm-Level Production Functions Using Proxy Variables to Control for Unobservables*.
- Ackerberg, Caves, and Frazer (2015), *Identification Properties of Recent Production Function Estimators*.

Concentrating-out and dynamic productivity process context:
- Doraszelski and Jaumandreu (2013), *R&D and Productivity: Estimating Endogenous Productivity*.
- Doraszelski and Jaumandreu (2018), related implementation papers on endogenous productivity dynamics and structural estimation.

Suggested paper wording position:
- Main text: concise statement of hard-linked constraint and reparameterization purpose.
- Appendix/footnote: explicit mapping formula and feasibility condition with implementation detail (`amc_lb`, `amc_pad`).
