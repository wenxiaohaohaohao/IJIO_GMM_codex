# 1022_non_hicks 目录整理说明

本次整理目标：把脚本、输入数据、中间数据、最终结果、临时文件分层，降低目录混乱度。

## 当前目录结构

- `code/master/`：主控与入口脚本（`Master_*.do`、`run_*.do`）
- `code/estimate/`：估计与 bootstrap 脚本
- `code/figure/`：图形与分解脚本
- `code/prep/`：数据预处理与 IV 构造脚本
- `data/raw/`：基础输入数据
- `data/work/`：中间产物
- `results/data/`：最终结果数据
- `results/figures/`：图形输出目录（待后续运行生成）
- `results/tables/`：表格输出目录（待后续运行生成）
- `results/logs/`：日志输出目录
- `archive/tmp_editor/`：编辑器临时文件归档

## 本次迁移范围

- `.do` 脚本：已从根目录迁入 `code/*`
- `.dta` 文件：已按 `data/raw`、`data/work`、`results/data` 分层
- 编辑器临时文件：已归档到 `archive/tmp_editor`

## 台账文件

- `MANIFEST_moves_do.csv`：脚本迁移清单
- `MANIFEST_moves_data.csv`：数据与临时文件迁移清单
- `MANIFEST.md`：本次整理摘要与分层统计

## 重要说明

- 本次不运行 Stata，仅做目录整理与文件迁移。
- 现有 `.do` 内部路径（尤其硬编码绝对路径）尚未全面重构，后续建议再做一轮“路径宏化”清理。
