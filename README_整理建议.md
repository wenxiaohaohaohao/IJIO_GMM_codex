# 根目录盘点与整理建议

生成时间: 2026-02-08 13:35:20
范围: 仅当前工作区根目录（不递归）

## 1) 总览
- 目录数: 5
- 文件数: 15

## 2) 文件分类统计
- 代码脚本: 2 个文件, 约 0.02 MB
- 数据文件(只读): 8 个文件, 约 345.27 MB
- 项目配置/其他: 1 个文件, 约 0 MB
- 正文/文档: 4 个文件, 约 0 MB

## 3) 根目录文件清单（按分类）

### 代码脚本
- Descriptive statistics.do | .do | 0.01 MB | 2025-09-06 02:49:04
- Descriptive statistics_0907.do | .do | 0.01 MB | 2026-01-24 17:12:07

### 数据文件(只读)
- Brandt-Rawski investment deflator.dta | .dta | 0 MB | 2025-08-07 22:56:06
- firststage.dta | .dta | 36.78 MB | 2025-08-30 12:09:51
- firststagecd.dta | .dta | 180.77 MB | 2025-08-28 01:51:39
- firststagehicks.dta | .dta | 4.03 MB | 2025-08-31 12:40:59
- junenewg_0829.dta | .dta | 54.39 MB | 2025-08-27 23:51:19
- junenewg_0902.dta | .dta | 63.64 MB | 2025-09-02 22:45:13
- OLStariff_yu_style.dta | .dta | 2.83 MB | 2026-01-05 00:21:51
- processing_vars_yu_style.dta | .dta | 2.83 MB | 2026-01-05 00:22:37

### 项目配置/其他
- IJIO_GMM_wenxiao.code-workspace | .code-workspace | 0 MB | 2026-01-27 21:18:27

### 正文/文档
- AGENTS.md | .md | 0 MB | 2026-01-22 19:43:22
- README_整理建议.md | .md | 0 MB | 2026-02-08 13:10:35
- Table1_desc.tex | .tex | 0 MB | 2026-02-08 13:32:36
- Table2_byOwnership.tex | .tex | 0 MB | 2026-02-08 13:32:36

## 4) 疑似重复/冲突候选（仅标记，不删除）
- 未发现“同名目录 + 压缩包并存”项（根目录层级）。
- 可能的多版本 do 文件组:
  - 前缀 Descriptive statistics: Descriptive statistics.do, Descriptive statistics_0907.do

## 5) 最小侵入整理建议（下一步）
- 第一步: 根目录仅保留“入口文件”（如 AGENTS.md、工作区文件、总说明），其余先规划迁移但暂不移动。
- 第二步: 将 do 脚本按主题归入统一代码目录（如 03_代码/），先从描述性统计脚本开始。
- 第三步: 将 dta 明确标注为只读数据，避免与可执行脚本混放。
- 第四步: 后续以 `1017/` 为主工作区逐步整理，根目录只保留“入口+索引”角色。
