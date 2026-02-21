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
