# E的诊断

更新日期：2026-03-08

## 状态更新

以下结果记录的是一次历史试验口径：

- `lnM = ln(MI*1000/e)`
- `m = ln(MI*1000/e)`
- 样本门槛为 `drop if MI <= 0`

当前主代码已经回退为国内中间品口径：

- `lnM = ln(domesticint)`
- `m = ln(delfateddomestic)`
- 样本门槛恢复为 `drop if domesticint <= 0`

因此，本文件中的 `E/EP/EM/EH` 数值结果应视为历史诊断记录，不再作为当前主代码的正式 benchmark。

## 1. 本轮工作的范围

本轮只在 `G1_17_19` 上测试了 `E` 家族的若干 IV 版本，没有运行 `G2`。

本轮共同前提：

- 主模型仍是当前 Stata 的 V1 linked system，不改 evaluator 主体。
- 中间品口径统一为：
  - `lnM = ln(MI*1000/e)`
  - `m = ln(MI*1000/e)`
- 样本门槛改为：
  - 删除 `drop if domesticint <= 0`
  - 改为 `rename ... MI` 之后 `drop if MI <= 0`

## 2. 用来判断问题来源的关键对照

为了区分“样本/变量口径变化”与“E 组 IV 本身”的影响，我做了一个关键对照：

- 在同样的新样本、新变量口径下，只把 `IV_SET` 换回 `A`。

结果：

| 版本 | 含义 | N | b_m | b_l | b_k | elas_k_mean | elas_l_mean | elas_k_negshare | J_opt | J_p |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `A_same_sample` | 同一新样本下的 `A` 组 | 28926 | 0.8103 | 0.0445 | -0.0265 | 0.0446 | 0.1136 | 0.0000 | 498.39 | 0 |

这个对照说明：

1. 负的 `K/L` 不是主要由样本扩张或 `MI` 口径统一引起的。
2. 主要问题来自 `E` 家族的 IV 设计本身。

## 3. 各种 E 版本的结果

### 3.1 试过的版本

| 版本名 | IV 定义 | 说明 |
|---|---|---|
| `E0` | `const k ksq klag ksqlag llag lsqlag mlag mlagsq llagk mlagk mlagllag llagklag` | 最初按技术说明实现的 E |
| `E1` | `const klag ksqlag llag lsqlag mlag mlagsq llagk mlagk mlagllag llagklag` | 去掉当期 `k/ksq`，保留交互项 |
| `E` | `const klag ksqlag llag lsqlag mlag mlagsq` | 目前保留的主版本，最保守 |
| `EP` | `E + Z_tariff + Z_HHI_post` | 外生 shifter 双补充 |
| `EM` | `E + Z_tariff + l_ind_yr + k_ind_yr + m_ind_yr` | 你的“建议 1” |
| `EH` | `E + Z_HHI_post` | 你的“建议 2” |

### 3.2 结果汇总

| 版本 | N | b_m | b_l | b_k | elas_k_mean | elas_l_mean | elas_k_negshare | elas_l_negshare | J_opt | J_df | J_p |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `E0` | 28926 | 0.8636 | -0.0658 | -0.4432 | 0.0271 | 0.0676 | 0.3838 | 0.0000 | 408.07 | 6 | 0 |
| `E1` | 28926 | 0.8630 | -0.2134 | -0.3622 | 0.0208 | 0.0693 | 0.3903 | 0.0672 | 263.77 | 4 | 0 |
| `E` | 28926 | 0.8405 | 0.2634 | -0.7649 | 0.0032 | 0.1068 | 0.5069 | 0.0000 | 212.81 | 0 | `.` |
| `EP` | 28926 | 0.8756 | 0.0492 | -0.6194 | -0.0045 | 0.0794 | 0.5339 | 0.0000 | 170.33 | 2 | 1.03e-37 |
| `EM` | 28926 | 0.8312 | 0.1440 | -0.7280 | -0.0001 | 0.1296 | 0.5173 | 0.0000 | 318.86 | 4 | 0 |
| `EH` | 28926 | 0.8756 | 0.0492 | -0.6194 | -0.0045 | 0.0794 | 0.5339 | 0.0000 | 170.26 | 2 | 6.49e-39 |

说明：

- `E0`、`E1`、`EP`、`EM`、`EH` 的数值来自本轮正式运行记录与留档结果。
- 当前无后缀主结果文件对应的是 `E` 版本。

## 4. 诊断结论

### 4.1 结论一：E 家族的问题在 instrument layer，不在样本口径

`A_same_sample` 下并没有出现同样严重的 `K/L` 异常，因此主因不是：

- `MI*1000/e` 口径统一本身
- `drop if MI <= 0` 带来的样本变化

主因是 `E` 家族的工具变量组合无法稳定识别资本项。

### 4.2 结论二：E0 的问题是“资本自我工具化”太强

`E0` 含有当期 `k` 和 `ksq`，这会让资本识别变得过于机械：

- 一方面表面上看“很强”
- 另一方面过识别检验极差
- 并且 `b_k` 与资本弹性分布都明显不合理

### 4.3 结论三：把 E 收缩为纯滞后多项式以后，J 下降了，但 K 没有救回来

`E1 -> E` 的过程中：

- `J_opt` 从 `263.77` 继续降到 `212.81`
- `L` 回正
- 但 `K` 更差，`elas_k_negshare` 升到 `0.5069`

这说明“纯滞后多项式型 E”过弱，资本识别被压扁了。

### 4.4 结论四：两种 E+ 都不能接受

`EM` 与 `EH` 的比较：

- 按拟合看：`EH` 更好，`J_opt=170.26` 低于 `EM=318.86`
- 按经济形状看：`EM` 略好，但 `b_k` 仍很差，资本平均弹性仍接近 0

因此：

- `EM` 不能用
- `EH` 也不能用
- 当前没有任何一个 `E` 家族版本达到“可以继续跑 G2”的标准

## 5. 当前保留的主代码状态

为了让主代码回到干净状态，已做如下清理：

1. `bootstrap1229_group.do` 中只保留了 `E`，删除了 `EP/EM/EH` 分支。
2. 删除了对应的试验入口脚本：
   - `run_iv_ep_g1.do`
   - `run_iv_em_g1.do`
   - `run_iv_eh_g1.do`
3. 重新运行了主 `E`，让无后缀主输出文件回到当前保留的主版本。

当前主版本的 `E` 定义是：

```stata
const klag ksqlag llag lsqlag mlag mlagsq
```

## 6. 为什么下一步考虑转向 `GMM_ind1.prg`

原因不是“Gauss 一定更好”，而是：

1. 当前在 Stata 里对 `E` 家族做的是经验性调参。
2. 这些调参已经说明：单纯靠手工拼接 `E/E+/EM/EH`，很难把资本识别拉回来。
3. `GMM_ind1.prg` 里已经有一个更完整、成体系的 instrument 逻辑，尤其是 `instru=2`。

所以更合理的下一步不是继续微调 `E`，而是：

> 先把 `GMM_ind1.prg` 的 instrument logic 精确拆解，再决定是否把它映射到当前 Stata 主系统。

## 7. 我会怎么转 `GMM_ind1.prg` 的逻辑

### 7.1 不是直接整段照搬

不会直接把 `GMM_ind1.prg` 整段重写进当前 Stata 主代码。原因是两边不是同一个估计系统：

- 当前 Stata 主代码是 V1 linked system
- `GMM_ind1.prg` 是 Gauss 的另一套 GMM 实现
- 两者的 evaluator、第一步对象、集中化参数块都不一样

因此不能“整体复制”。

### 7.2 可以直接转的部分：instrument layer

`GMM_ind1.prg` 里最值得转的是 `compute(b)` 中 `instru=2` 的工具变量结构：

```gauss
z = ct ~ td ~ east ~ middle ~ core ~ ccity ~ entrant1 ~ scost1
    ~ pol2(k1,m1) ~ pol1(l1) ~ pol2(rml1,avga1);
```

这里的思路是：

1. 常数项与年份项
2. 地区/区位 shifter
3. 进入状态与销售成本控制
4. 以滞后状态变量为核心的多项式块
5. 再加上 `rml1` 与 `avga1` 这类和 markdown / 成本结构相关的滞后 proxy

### 7.3 当前 Stata 代码里哪些对象已经有

已经存在或容易生成的对象：

- `const`
- 年份虚拟变量 `dy2002-dy2007`
- `klag`, `ksqlag`
- `llag`, `lsqlag`
- `mlag`, `mlagsq`
- `l_ind_yr`, `k_ind_yr`, `m_ind_yr`
- `Z_tariff`, `Z_HHI_post`
- `age`, `lnage`

### 7.4 当前 Stata 代码里哪些对象还没有

`GMM_ind1.prg` 的 `instru=2` 想精确映射，当前至少还缺这些对象：

- `east`, `middle`, `core`, `ccity`
- `entrant1`
- `scost1`
- `rml1`
- `avga1`
- 三次项：`k1^3`, `m1^3`, `l1^3`
- 若完全照 Gauss 的 `pol2()` / `pol1()` 定义，还要对应交互项

其中最关键的不是高次项，而是：

- `scost1`
- `rml1`
- `avga1`
- 区域 dummy

因为这些对象在 Gauss 里不是随便加的，它们服务于 markdown / cost-side 的识别。

### 7.5 我建议的具体转法

如果决定正式转向 `GMM_ind1.prg`，我会按下面顺序做，而不是直接动主系统：

#### 第一步：做变量映射表

把 `GMM_ind1.prg` 里用到的对象逐个映射到当前 Stata 数据：

| Gauss 对象 | 含义 | 当前 Stata 是否已有 | 处理方式 |
|---|---|---|---|
| `ct` | 常数项 | 有 | 直接用 `const` |
| `td` | 年份虚拟变量 | 有 | 直接用 `dy2002-dy2007` |
| `k1,m1,l1` | 滞后状态变量 | 有 | 直接用 `klag/mlag/llag` |
| `east,middle,core,ccity` | 区域 / 区位 | 不明确 | 先查原始数据字段 |
| `entrant1` | 进入者滞后状态 | 需构造 | 用 `age` 或成立年构造 |
| `scost1` | 销售成本滞后 | 当前没有明确同口径对象 | 需决定是否用管理费用近似，或另找销售费用变量 |
| `rml1` | 材料-劳动结构 proxy | 当前没有同名对象 | 需重新构造 |
| `avga1` | markdown / PAVCM proxy 的滞后值 | 当前没有 | 需设计替代 proxy 或单独第一步 |

#### 第二步：只转工具变量，不动 evaluator

这一步非常重要：

- 不改 `X`
- 不改 `X_lag`
- 不改 `SHAT`
- 不改 `OMEGA`
- 不改 `POOL -> gb -> XI`

只新增一个新的 `IV_SET`，例如 `GA2`，专门承载 Gauss `instru=2` 的 Stata 映射版 `Z`。

#### 第三步：先做“可实现子集”

如果 `scost1/rml1/avga1/区域 dummy` 一时映射不全，不应该硬上完整 Gauss 版。

正确做法是先分两层：

- `GA2_partial`：只用当前可精确构造的部分
- `GA2_full`：补齐 proxy 之后再上

#### 第四步：只跑 G1

仍然先只跑 G1，并且固定：

- `RUN_POINT_ONLY=1`
- `RUN_BOOT=0`
- `RUN_DIAG=1`

比较对象至少包括：

- `A`
- 当前保留的 `E`
- `GA2_partial`
- 如果能做出来，再加 `GA2_full`

## 8. 当前建议

给 GPT 看时，可以直接让它回答两个问题：

1. `GMM_ind1.prg` 的 `instru=2` 在当前 Stata 数据口径下，哪些变量能精确映射，哪些不能？
2. 如果不做完整移植，最合理的 `GA2_partial` 应该保留哪一组变量？

我的当前判断是：

- 继续在 `E/EP/EM/EH` 上微调，收益已经很低
- 下一步更值得做的是“有组织地转 `GMM_ind1.prg` 的 instrument logic”
- 但前提是先做变量映射，而不是直接照搬
