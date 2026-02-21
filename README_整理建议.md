# 根目录盘点与整理建议

生成时间: 2026-02-17 01:20:00
范围: 仅当前工作区根目录（不递归）

## 1) 总览
- 目录数: 5
- 文件数: 22

## 2) 文件分类统计
- 代码脚本: 6 个文件, 约 0.02 MB
- 数据文件(只读): 8 个文件, 约 345.27 MB
- 项目配置/其他: 2 个文件, 约 0 MB
- 正文/文档: 6 个文件, 约 196.32 MB

## 3) 根目录文件清单（按分类）

### 代码脚本
- Descriptive statistics.do | .do | 0.01 MB | 2025-09-06 02:49:04
- Descriptive statistics_0907.do | .do | 0.01 MB | 2026-01-24 17:12:07
- mata_gmm_template.do | .do | 0.00 MB | 2026-02-12 22:59:25
- tmp_patch_v1_diag.py | .py | 0.00 MB | 2026-02-16 00:00:00
- tmp_patch_v1_mata.py | .py | 0.01 MB | 2026-02-15 23:49:00
- tmp_patch_v1_output.py | .py | 0.00 MB | 2026-02-15 23:55:00

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
- .gitignore | .ignore | 0 MB | 2026-02-08 18:29:39
- IJIO_GMM_wenxiao.code-workspace | .code-workspace | 0 MB | 2026-01-27 21:18:27

### 正文/文档
- AGENTS.md | .md | 0 MB | 2026-01-22 19:43:22
- README_整理建议.md | .md | 0 MB | 2026-02-17 01:20:00
- Table1_desc.tex | .tex | 0 MB | 2026-02-08 13:32:36
- Table2_byOwnership.tex | .tex | 0 MB | 2026-02-08 13:32:36
- tmp_var_dict.docx | .docx | 0.02 MB | 2026-02-08 18:53:00
- 文章参考.zip | .zip | 196.32 MB | 2026-02-16 01:18:00

## 4) 疑似重复/冲突候选（仅标记，不删除）
- 未发现 同名目录 + 压缩包并存项（根目录层级）。
- 可能的多版本脚本组合:
  - 前缀 Descriptive statistics: Descriptive statistics.do, Descriptive statistics_0907.do
  - 临时补丁：tmp_patch_v1_diag.py / tmp_patch_v1_mata.py / tmp_patch_v1_output.py（仅在测试阶段使用，后续可归入 workflow/scripts）

## 5) 最小侵入整理建议（下一步）
- 第一步: 根目录仅保留入口文件（如 AGENTS.md、工作区文件、总说明），先把 tmp_patch_* 这类临时补丁移动到 workflow/scripts/temp/ 或 1017/tmp/。
- 第二步: 将 .do 脚本和 mata 模板按版块归入 code/ 目录，减少根目录暴露的脚本。
- 第三步: 把 文章参考.zip 和 tmp_var_dict.docx 的用途、版本说明写在 1017/ 相关目录，保持根目录为索引。
- 第四步: 将根目录数据文件标注为只读并在 MANIFEST.md 里追踪更新情况（如当前的 junenewg 与 firststage 系列）。
