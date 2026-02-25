# 代码修正总结 (2026年2月25日)

## 概述

今天针对 Stata 主脚本进行了两项重要修改，解决时间戳文件夹增殖和数据存储混乱问题。

---

## 问题1：时间戳文件夹增殖

### 问题描述

运行 `run_step1_point_diag.do` 每次都会创建新的时间戳子文件夹（如 `run_20260224_102900/`），导致：

- 24+ 个冗余的时间戳目录堆积
- 文件分散在不同路径，难以管理
- 输出日志和数据位置不一致

### 根本原因

[1017/1022_non_hicks/code/master/run_step1_point_diag.do](1017/1022_non_hicks/code/master/run_step1_point_diag.do) 中包含以下逻辑：

```stata
# 旧代码（第11-18行）❌
local run_date = string(date(c(current_date), "DMY"), "%tdCCYYNNDD")
local run_time = subinstr(c(current_time), ":", "", .)
global RUN_TAG "`run_date'_`run_time'"
global DATA_WORK "$ROOT/data/work/run_$RUN_TAG"
global RES_DATA "$ROOT/results/data/run_$RUN_TAG"
global RES_LOG "$ROOT/results/logs/run_$RUN_TAG"
```

每次执行都产生新的时间戳，创建隔离的子目录。

### 修改方案

**移除时间戳逻辑，使用标准的全局变量定义**

| 位置     | 文件                        | 修改                     | commit ID   |
| -------- | --------------------------- | ------------------------ | ----------- |
| 第1-31行 | `run_step1_point_diag.do` | 替换为标准的全局变量定义 | `318c00a` |

**新代码** ✅

```stata
if ("$ROOT"=="") global ROOT "D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks"
if ("$CODE"=="") global CODE "$ROOT/code"
if ("$DATA_RAW"=="") global DATA_RAW "$ROOT/data/raw"
if ("$DATA_WORK"=="") global DATA_WORK "$ROOT/data/work"
if ("$RES_DATA"=="") global RES_DATA "$ROOT/results/data"
if ("$RES_FIG"=="") global RES_FIG "$ROOT/results/figures"
if ("$RES_LOG"=="") global RES_LOG "$ROOT/results/logs"

# 创建标准输出目录
capture mkdir "$DATA_WORK"
capture mkdir "$RES_DATA"
capture mkdir "$RES_FIG"
capture mkdir "$RES_LOG"
```

### 修改效果

| 方面     | 旧方式 ❌                                  | 新方式 ✅                        |
| -------- | ------------------------------------------ | -------------------------------- |
| 每次运行 | 创建新的 `run_YYYYMMDD_HHMMSS/` 子文件夹 | 使用统一的标准路径               |
| 文件位置 | 分散在时间戳目录                           | 集中在 `data/work/` 等标准位置 |
| 文件覆盖 | 冲突（不同路径）                           | 支持 replace mode                |

---

## 问题2：数据存储位置混乱

### 问题描述

数据文件存储在两个不同位置：

- **`$DATA_WORK`**: 中间数据（由 `bootstrap1229_group.do` 保存）
- **`$RES_DATA`**: 聚合结果（由 `Master_Non_hicks.do` 保存）

这导致输出数据分散，难以追踪完整的数据流程。

### 原始文件位置分析

#### bootstrap1229_group.do（8个文件到 $DATA_WORK）

```stata
save "$DATA_WORK/firststage_`GROUPNAME'.dta", replace                    # 行218
save "$DATA_WORK/elasticity_group_`GROUPNAME'.dta", replace             # 行1024
save "$DATA_WORK/omega_xi_group_`GROUPNAME'.dta", replace               # 行1042
save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace              # 行1116
save "$DATA_WORK/iv_diag_group_`GROUPNAME'.dta", replace                # 行1204
save "$DATA_WORK/bootstrap_failures_`GROUPNAME'.dta", replace           # 行1319
save "$DATA_WORK/gmm_point_group_`GROUPNAME'.dta", replace              # 行1391
save "$DATA_WORK/gmm_boot_group_`GROUPNAME'.dta", replace               # 行1395
```

#### Master_Non_hicks.do（3个文件到 $RES_DATA）- ❌ 混合存储

```stata
save "$RES_DATA/nonhicks_points_by_group.dta", replace                  # 行141
save "$RES_DATA/nonhicks_ses_by_group.dta", replace                     # 行149
save "$RES_DATA/gmm_point_industry.dta", replace                        # 行190
```

### 修改方案：方案A（用户选择）

**统一所有数据到 `$DATA_WORK`**

| 文件                    | 修改内容                               | commit ID   |
| ----------------------- | -------------------------------------- | ----------- |
| `Master_Non_hicks.do` | `$RES_DATA` → `$DATA_WORK`（3处） | `3bb51eb` |

### 修改详情

**修改1**（行141）

```stata
# 旧代码 ❌
save "$RES_DATA/nonhicks_points_by_group.dta", replace

# 新代码 ✅
save "$DATA_WORK/nonhicks_points_by_group.dta", replace
```

**修改2**（行149）

```stata
# 旧代码 ❌
save "$RES_DATA/nonhicks_ses_by_group.dta", replace

# 新代码 ✅
save "$DATA_WORK/nonhicks_ses_by_group.dta", replace
```

**修改3**（行190）

```stata
# 旧代码 ❌
save "$RES_DATA/gmm_point_industry.dta", replace

# 新代码 ✅
save "$DATA_WORK/gmm_point_industry.dta", replace
```

### 修改效果

#### 统一数据位置：`$ROOT/data/work/`

```
data/work/
├── firststage_G1_17_19.dta
├── firststage_G2_39_41.dta
├── elasticity_group_G1_17_19.dta
├── elasticity_group_G2_39_41.dta
├── omega_xi_group_G1_17_19.dta
├── omega_xi_group_G2_39_41.dta
├── gmm_point_group_G1_17_19.dta
├── gmm_point_group_G2_39_41.dta
├── gmm_boot_group_G1_17_19.dta
├── gmm_boot_group_G2_39_41.dta
├── nonhicks_points_by_group.dta    ← 新位置 ✅
├── nonhicks_ses_by_group.dta       ← 新位置 ✅
├── gmm_point_industry.dta          ← 新位置 ✅
├── iv_diag_group_*.dta
└── bootstrap_failures_*.dta
```

#### 对比表

| 指标           | 旧方式 ❌                             | 新方式 ✅             |
| -------------- | ------------------------------------- | --------------------- |
| 数据分散位置数 | 2个（`$DATA_WORK` + `$RES_DATA`） | 1个（`$DATA_WORK`） |
| 数据追踪复杂度 | 高（需切换目录查看）                  | 低（统一位置）        |
| 文件查找难度   | 高                                    | 低                    |
| 覆盖操作       | 可能冲突                              | 一致                  |

---

## 代码执行流程（修改后）

```
Master_Non_hicks.do (主脚本)
  │
  ├─→ run_group_G1.do (G1组执行)
  │     └─→ bootstrap1229_group.do
  │           ├─ 保存: firststage_G1_17_19.dta → $DATA_WORK ✅
  │           ├─ 保存: elasticity_group_G1_17_19.dta → $DATA_WORK ✅
  │           ├─ 保存: omega_xi_group_G1_17_19.dta → $DATA_WORK ✅
  │           ├─ 保存: gmm_point_group_G1_17_19.dta → $DATA_WORK ✅
  │           ├─ 保存: gmm_boot_group_G1_17_19.dta → $DATA_WORK ✅
  │           └─ 保存: iv_diag_group_G1_17_19.dta → $DATA_WORK ✅
  │
  ├─→ run_group_G2.do (G2组执行)
  │     └─→ bootstrap1229_group.do
  │           └─ [同上，G2版本]
  │
  └─→ 聚合结果
      ├─ 读取: $DATA_WORK/gmm_point_group_G1_17_19.dta
      ├─ 读取: $DATA_WORK/gmm_point_group_G2_39_41.dta
      ├─ 保存: nonhicks_points_by_group.dta → $DATA_WORK ✅
      ├─ 保存: nonhicks_ses_by_group.dta → $DATA_WORK ✅
      └─ 保存: gmm_point_industry.dta → $DATA_WORK ✅
```

---

## 总结表

| 问题             | 根本原因                               | 修改方案                      | 修改文件                    | Commit ID   | 预期效果              |
| ---------------- | -------------------------------------- | ----------------------------- | --------------------------- | ----------- | --------------------- |
| 时间戳文件夹增殖 | `local run_time` 创建隔离子目录      | 移除RUN_TAG，使用标准全局变量 | `run_step1_point_diag.do` | `318c00a` | ✅ 无时间戳文件夹产生 |
| 数据位置混乱     | 分散在 `$DATA_WORK` 和 `$RES_DATA` | 统一所有输出到 `$DATA_WORK` | `Master_Non_hicks.do`     | `3bb51eb` | ✅ 数据集中管理       |

---

## 影响范围

### ✅ 受益的功能

- 数据管理更清晰
- 输出日志集中位置
- 文件覆盖操作无冲突
- 后续维护更容易

### ⚠️ 需要验证的点

1. **运行 `run_step1_point_diag.do`** - 验证不产生新的时间戳文件夹
2. **运行 `Master_Non_hicks.do`** - 验证所有输出文件都在 `$DATA_WORK` 中
3. **文件覆盖测试** - 验证 replace mode 正常工作

### 📝 备注

- 全局变量 `$RES_DATA` 和 `$RES_FIG` 的定义仍保留（向后兼容），但不再使用
- `$RES_FIGv` 仍用于图表存储（暂不修改）
- 两处修改都是向后兼容的，不会破坏现有数据

---

## 验证清单

请运行以下命令进行验证：

### 检查1：确认无时间戳文件夹

```bash
ls -la data/work/
# 应只看到文件，不见 run_20260225_* 目录
```

### 检查2：确认文件都在标准位置

```stata
// 在Stata中验证
use "D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\data\work\nonhicks_points_by_group.dta", clear
describe
// 应成功加载，无路径错误
```

### 检查3：查看日志位置

```bash
ls -la results/logs/
# 应见到 main_twogroups_full_log_YYYYMMDD.log
# 不见 run_20260225_* 目录
```

---

## 相关文件一览

| 文件路径                                                     | 修改状态    | 原因              |
| ------------------------------------------------------------ | ----------- | ----------------- |
| `1017/1022_non_hicks/code/master/run_step1_point_diag.do`  | ✏️ 已修改 | 移除RUN_TAG       |
| `1017/1022_non_hicks/code/master/Master_Non_hicks.do`      | ✏️ 已修改 | 路径统一          |
| `1017/1022_non_hicks/code/master/run_group_G1.do`          | ✅ 无需改   | 已使用标准路径    |
| `1017/1022_non_hicks/code/master/run_group_G2.do`          | ✅ 无需改   | 已使用标准路径    |
| `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do` | ✅ 无需改   | 已使用 $DATA_WORK |

---

**请审核以上修改，确认无误后可以合并到主分支。**
