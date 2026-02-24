# 1022_non_hicks Workflow Master

Last update: 2026-02-21

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

## 8. Robustness Branch Order (Frozen)

Use the robustness sequence below and keep the main specification unchanged:

- R0: Structure-matched IV robustness (Yinheng/RDP-style IV construction)
- R1: Standard IV robustness (A/B/C variants around baseline)
- R2: Dynamic-law robustness (alternative productivity transition, e.g., higher-order terms)
- R3: Sample robustness (industry/time-window/subsample checks)

R0 is mandatory before R1-R3 because it directly tests whether a control-function/concentrating-out-consistent IV design changes convergence quality, over-identification behavior, and elasticity plausibility.

## 9. Appendix-Ready English Method Note (IV Logic)

### A. Why add R0 (Structure-matched IV robustness)

Our baseline estimation uses a two-step GMM framework with a control-function structure and concentrating-out for the linear productivity-transition block. In this setting, identification quality depends not only on instrument relevance in a generic linear-IV sense, but also on whether instruments are aligned with the model's information structure (predetermined states and lagged observables entering the control-function recursion). Therefore, we add a dedicated robustness layer (R0) that constructs instruments following the Yinheng/RDP-style logic: lagged state variables and low-order polynomial terms consistent with the timing assumptions used by the control-function/concentrating-out system.

### B. Econometric rationale

The rationale is threefold. First, under control-function identification, valid instruments should be measurable with respect to the firm's information set prior to current-period shocks, so lagged states and their polynomial transformations are natural candidates. Second, concentrating-out reduces dimensionality by partialling out linear transition parameters at each candidate nonlinear vector, which makes the nonlinear moments highly sensitive to instrument geometry; structure-matched instruments can improve numerical conditioning and reduce weak-identification symptoms. Third, comparing baseline IVs with structure-matched IVs provides an internal cross-validation of identification assumptions: if key parameters keep their sign and order of magnitude while diagnostics improve, results are less likely to be driven by ad hoc instrument choice.

### C. Implementation and decision rule

We do not replace the baseline specification mechanically. Instead, we run R0 as a robustness layer and compare (i) convergence behavior, (ii) over-identification diagnostics, and (iii) elasticity plausibility (including negative-share frequencies). The baseline is retained as the main specification unless the structure-matched set simultaneously improves diagnostics and preserves economically coherent parameter patterns. This design separates "model structure validation" from "specification replacement," and keeps the empirical narrative transparent.

## 10. Temp Files Audit (Root)

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

## 11. Step 1 Log Read Policy (Execution Standard)

This section is mandatory for future Step 1 runs (`point + diagnostics`, no bootstrap).

### 11.1 Must-read logs

1. `1017/1022_non_hicks/run_step1_point_diag.log`
2. `1017/1022_non_hicks/main_twogroups_full_log_YYYYMMDD.log` (same run date, latest timestamp only)

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
3. Old root logs from previous dates, including outdated `main_twogroups_full_log_*.log`

### 11.4 Fixed screening rules

1. Record current run start timestamp before launching Stata.
2. Read only logs with `LastWriteTime >= run start timestamp`.
3. Always read must-read logs first.
4. Read conditional logs only if must-read logs indicate failure or inconsistency.
5. Do not use archive logs as evidence for current-run conclusions.

## 12. Hard-Constraint Reparameterization Note (2026-02-24)

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
