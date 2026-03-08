# IV_SET = E 技术说明（给 Codex）

## 任务目标

本次修改只做两件事：

1. **把当前主代码 `bootstrap1229_group.do` 的基准 IV 方案切换为新的 `E` 层 IV 集合**；
2. **统一一阶段与二阶段中间品变量口径**，将原来的
   - `lnM = ln(domesticint)`
   - `m = ln(delfateddomestic)`
   改为统一的
   - `lnM = ln(MI*1000/e)`
   - `m = ln(MI*1000/e)`

本次修改**不是**重新设计估计系统；它是在保留当前 V1 linked-system 主体结构的前提下，重构 instrument layer，并修正中间品变量口径不一致的问题。

---

## 方法论定位：为什么 `E` 必须以 `IV_SET="E"` 的方式进入

### 1. `E` 是 **GMM 工具变量集合**，不是结构方程本体

当前主代码已经把 V1 linked system 写成：

- 结构方程右侧：`X = (const, l, k, lsq, ksq, m)`
- 滞后结构方程右侧：`X_lag = (const, llag, klag, lsqlag, ksqlag, mlag)`
- linked constraint 输入：`SHAT`, `SHAT_lag`
- 外层 evaluator 中通过 `S = 1 - exp(-SHAT)/amc`、`S_lag = 1 - exp(-SHAT_lag)/amc` 更新 share constraint
- 动态块通过 `POOL -> gb=qrsolve(POOL, OMEGA) -> XI` 完成 concentration-out

因此，`E` 的正确进入位置只能是：

> **进入 `Z` 矩阵选择分支，服务于 moment condition 和 two-step GMM 权重矩阵。**

不能把 `E` 的变量：

- 塞进 `X` 或 `X_lag`；
- 塞进一阶段 share 回归 `h(·)` 的右侧；
- 直接改 `POOL`、`OMEGA`、`XI` 的定义；
- 直接改 bootstrap 主流程。

### 2. 这与 BOSTON / 尹恒的共同方法论一致

- **BOSTON** 的一般框架是：
  - 把残差写成 `xi = y(beta) - w(beta) * gamma`
  - 工具变量矩阵 `Z` 只进入 GMM 矩条件和权重矩阵
  - 线性参数通过 concentrating-out 处理，而不是把工具变量并入结构方程
- **尹恒** 的思路是：
  - Hansen 两步 GMM
  - 外生/预定状态变量的多项式作为工具变量
  - 工具变量要甄别
  - concentrating-out 降维

因此，对于你当前代码，正确做法不是“改模型”，而是：

> **在现有 `IV_SET` 框架里新增 `E` 分支，让 `E` 替换每次运行所用的 `Z`。**

这既保留了主代码结构，也保留了 A/B/C 与后续对照的可能性。

---

## 本次修改的边界（必须严格遵守）

### 允许修改的部分

1. `bootstrap1229_group.do` 中：
   - 样本清理与 `lnM` / `m` 的定义
   - `IV_SET` 合法值校验
   - `refresh_globals()` 中 `Z` 的 `E` 分支
   - `RUN_DIAG` 中 `z_E` 诊断工具集
2. `Master_Non_hicks.do`：
   - 运行示例中使用 `global IV_SET "E"`
   - 如需要，可把本轮实验默认值设为 `E`，但**不要删除 A/B/C**
3. `run_group_G1.do` / `run_group_G2.do`：
   - 如入口脚本中显式设置 `IV_SET`，同步改为 `E`

### 禁止修改的部分

1. 不要改 V1 的 evaluator 主体：
   - 不改 `S`, `S_lag` 的构造逻辑
   - 不改 `OMEGA`, `OMEGA_lag`
   - 不改 `POOL -> gb -> XI`
2. 不要改 `X` / `X_lag` 的列结构
3. 不要改第一阶段多项式规格，只允许其因 `lnM` 口径变化而机械变化
4. 不要删除 A/B/C/A1/A2/A3 分支
5. 不要自动重构 bootstrap 主流程

---

## 变量口径更新：中间品变量统一到 `MI*1000/e`

## 当前问题

当前代码中：

- 一阶段被解释变量构造来自 `lnR - lnM`，而 `lnM = ln(domesticint)`
- 二阶段结构方程中 `m = ln(delfateddomestic)`

这导致一阶段和二阶段对“国内/中间品投入”的口径不一致。

## 新要求（必须执行）

统一改为：

- `lnM = ln(MI*1000/e)`
- `m   = ln(MI*1000/e)`

其中 `MI` 已在代码中由

```stata
rename 工业中间投入合计千元 MI
```

生成；`R` 当前定义为人民币千元乘 `1000/e` 后的口径，因此 `MI*1000/e` 与 `R` 单位一致。

## 具体修改要求

### 1. 删除旧的 `domesticint` 过滤作为主样本门槛

当前代码顶部有：

```stata
drop if domesticint <= 0
```

本次修改后，**不再把 `domesticint` 作为 `lnM` / `m` 的样本门槛**。

### 2. 在 `MI` 定义之后，再进行中间品正值过滤

在这句之后：

```stata
rename 工业中间投入合计千元 MI
```

新增：

```stata
drop if MI <= 0
```

### 3. 替换 `lnM` 的定义

把当前：

```stata
gen double lnM = ln(domesticint) if domesticint>0
```

改为：

```stata
gen double lnM = ln(MI*1000/e) if MI>0
```

### 4. 替换 `m` 的定义

把当前：

```stata
gen m = ln(delfateddomestic)
```

改为：

```stata
gen double m = ln(MI*1000/e) if MI>0
```

### 5. 其他变量生成方式保持不变

以下对象本轮不主动重写：

- `ratio = importint/(domesticint+importint)`
- `MF = importint/einputp`
- `x = ln(X)`
- `r = ln(R)`
- 所有 lag / square / interaction 变量的生成方式

说明：本轮的目标只是**统一一阶段和二阶段的中间品主口径**，不是全面重写所有与 `domesticint` 相关的辅助对象。

---

## `E` 层 IV 的正式定义（必须用当前代码里的现成变量名）

本轮 `E` 集合定义为：

```stata
const k ksq klag ksqlag llag lsqlag mlag mlagsq llagk mlagk mlagllag llagklag
```

### 含义说明

- `const`：常数项
- `k`, `ksq`：当期资本及其平方
- `klag`, `ksqlag`：滞后资本及其平方
- `llag`, `lsqlag`：滞后劳动及其平方
- `mlag`, `mlagsq`：滞后中间品及其平方
- `llagk`：`llag * k`
- `mlagk`：`mlag * k`
- `mlagllag`：`mlag * llag`
- `llagklag`：`llag * klag`

这是一个 **Boston / 尹恒式“低阶多项式 + 关键交互项”的 E 层工具集**，但它严格使用了当前主代码已经生成的变量名，不新增新符号，不改估计对象。

---

## 代码修改步骤

## 步骤 1：扩展 `IV_SET` 合法值校验

在文件开头目前有：

```stata
if !inlist("`IV_SET'","A","B","C","A1","A2","A3") {
    di as err "ERROR: invalid IV_SET=[`IV_SET']; must be A, B, C, A1, A2, or A3."
}
```

改为支持 `E`：

```stata
if !inlist("`IV_SET'","A","B","C","A1","A2","A3","E") {
    di as err "ERROR: invalid IV_SET=[`IV_SET']; must be A, B, C, A1, A2, A3, or E."
}
```

同时保持：

```stata
global IV_SET "`IV_SET'"
```

不变。

---

## 步骤 2：更新样本清理与变量构造

### 2.1 删除旧过滤

删除或注释：

```stata
drop if domesticint <= 0
```

### 2.2 在 `MI` 定义后加入新过滤

在：

```stata
rename 工业中间投入合计千元 MI
```

后面立即加入：

```stata
drop if MI <= 0
```

### 2.3 更新 `lnM`

改成：

```stata
gen double lnM = ln(MI*1000/e) if MI>0
```

### 2.4 更新 `m`

改成：

```stata
gen double m = ln(MI*1000/e) if MI>0
```

### 2.5 保持后续 winsor 和 lag 逻辑不变

这些继续沿用：

```stata
winsor2 lnM, cuts(1 99) by(cic2 year) replace
gen double lratiofs = lnR - lnM
...
gen double mlag = L.m
...
gen double mlagsq = mlag^2
```

---

## 步骤 3：在 `refresh_globals()` 中新增 `IV_SET == "E"` 分支

在 Mata 里当前是按 `GROUP_NAME` 和 `IV_SET` 选择 `Z = st_data(...)`。

**新增一个组无关、两组通用的 `E` 分支**，并放在 A/B/C 分支之前或之后均可，但要保证逻辑可达。

建议写成：

```mata
else if (ivset=="E") {
    Z = st_data(., ("const","k","ksq","klag","ksqlag","llag","lsqlag","mlag","mlagsq","llagk","mlagk","mlagllag","llagklag"))
}
```

### 重要说明

- `E` 先定义为**两组共用**的统一 baseline IV 集
- 先不要做 `G1` / `G2` 的不同 `E` 版本
- 先不要在 `E` 里混入 `Z_tariff`、`Z_HHI_post`、`l_ind_yr`、`k_ind_yr`、`m_ind_yr`
- 这些对象以后如果要做 `E+` 或 `F`，再单独扩展

本轮的目的，是拿到一个**纯状态变量多项式型 baseline**。

---

## 步骤 4：在 `RUN_DIAG` 中同步新增 `z_E`

当前代码中 `RUN_DIAG` 只定义了 `z_A`, `z_B`, `z_C`。这会造成：

- 主 GMM 跑的是 `E`
- 但线性诊断还在跑 A/B/C

这是不允许的。

请新增：

```stata
local z_E const k ksq klag ksqlag llag lsqlag mlag mlagsq llagk mlagk mlagllag llagklag
```

并在 `IV_SET == "E"` 时调用 `z_E`。

如果 `RUN_DIAG` 目前是按组分别定义 `z_A/z_B/z_C`，那就仿照当前结构，对两组都加入统一的 `z_E`。

---

## 步骤 5：不要改 evaluator、本体动态块和 bootstrap

再次强调：本轮**禁止**对下列部分做结构性修改：

1. `X=(const,l,k,lsq,ksq,m)` 不改
2. `X_lag=(const,llag,klag,lsqlag,ksqlag,mlag)` 不改
3. `SHAT` / `SHAT_lag` 的读取不改
4. `S`, `S_lag` 的迭代内更新不改
5. `OMEGA`, `OMEGA_lag`, `POOL`, `gb`, `XI` 不改
6. two-step 权重矩阵逻辑不改
7. bootstrap 条件分支不改

本轮的核心是：

> **改口径 + 改 instrument set，不改 V1 linked evaluator 本体。**

---

## 推荐的运行方式（先点估，后 bootstrap）

### G1 点估

```stata
global TARGET_GROUP "G1_17_19"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "E"
do "/mnt/data/Master_Non_hicks.do"
```

### G2 点估

```stata
global TARGET_GROUP "G2_39_41"
global RUN_POINT_ONLY 1
global RUN_BOOT 0
global RUN_DIAG 1
global IV_SET "E"
do "/mnt/data/Master_Non_hicks.do"
```

### 全流程（两组 + bootstrap）

```stata
global TARGET_GROUP "ALL"
global RUN_POINT_ONLY 0
global RUN_BOOT 1
global RUN_DIAG 1
global IV_SET "E"
do "/mnt/data/Master_Non_hicks.do"
```

说明：

- 先跑点估，是为了确认 `E` 不会在当前样本和口径更新下直接引起权重矩阵或优化器崩溃。
- 不要一上来跑 bootstrap。

---

## 本轮验收标准

至少检查以下输出：

1. `gmm_conv == 1`
2. `J_p` 不是极端值（不是接近 0 也不是毫无识别感）
3. `b_m`, `b_amc`, `b_as`, `b_ar1_omega` 有稳定符号且数值不离谱
4. 点估阶段无 rank deficiency / singular matrix / invalid Z errors
5. `RUN_DIAG` 下 `z_E` 诊断能够正常跑通
6. 样本量变化可解释（因为 `m` 与 `lnM` 口径改了，允许样本轻微变化）

---

## 若 `E` 首轮运行失败，处理顺序

如果出现矩阵奇异、rank deficiency 或优化器极端不稳：

### 先做的事

1. 记录报错，不要静默改代码
2. 报告：
   - 哪一组失败（G1 还是 G2）
   - 是 `refresh_globals()` 构建 `Z` 时报错，还是 two-step 权重矩阵时报错，还是优化阶段不收敛

### 允许的第一顺位应急 trim（仅在明确报错后）

按下面顺序尝试删变量：

1. `llagklag`
2. `ksqlag`
3. `ksq`
4. `mlagsq`

但**不要在没有报错之前自动 trim**。

---

## 最后的方法论说明（给 Codex）

本轮一定要遵守这个原则：

> `E` 是一个新的 **IV layer**，不是新的 **model layer**。

因此：

- 它必须以 `IV_SET="E"` 的方式进入 `Z` 矩阵分支；
- 它不能通过改 `X`、改一阶段、改动态块、改 bootstrap 的方式进入；
- 中间品口径统一是一个**预处理层修正**，目的是让一阶段 `lnM` 和二阶段 `m` 指向同一个中间品对象，并与 `R` 口径一致；
- 除此之外，本轮不做额外系统重写。

