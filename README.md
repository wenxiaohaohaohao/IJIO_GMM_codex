# IJIO_GMM_codex_en

本仓库用于 IJIO 相关实证研究的代码、结果与资料管理，目标是保持可复现、可追踪、可快速迭代。

## 目录概览

- `methods/`：三种估计识别方法的主代码与结果
- `tariff_data/`：关税相关脚本与数据
- `figures/`：图表与导出结果
- `reference_materials/`：参考文献与外部材料（只读可调用）
- `备份/`：历史备份内容（只读可调用）
- `path_rules.md`：路径规则说明
- `AGENTS.md`：Codex 协作与执行规则
- `WORKFLOW_MASTER.md`：*工作流总纲与执行指南*
- `WORK_LOG.md`：*详细工作日志与进度记录*

## 工作区文件结构

```text
IJIO_GMM_codex_en/
├─ methods/                              [可删改替换]
│  ├─ non_hicks/                         [主要工作方向]
│  │  ├─ code/
│  │  │  ├─ prep/                        [数据预处理脚本]
│  │  │  ├─ estimate/                    [估计脚本] ⭐ bootstrap1229_group.do (主代码)
│  │  │  ├─ figure/                      [图表生成脚本]
│  │  │  ├─ master/                      [主控脚本]
│  │  │  └─ backup_latest_20260224_*/    [最新备份]
│  │  ├─ data/                           [工作数据]
│  │  └─ results/                        [估计结果]
│  ├─ non_markdown_non_hicks/            [备选估计方向]
│  │  ├─ code/
│  │  ├─ data/
│  │  └─ results/
│  └─ cobb_douglas/                      [Cobb-Douglas 估计]
│     ├─ code/
│     ├─ data/
│     └─ results/
├─ tariff_data/                          [关税数据与处理]
├─ figures/                              [最终图表输出]
├─ reference_materials/                  [只读可调用]
├─ 备份/                                  [只读可调用]
├─ AGENTS.md                             [规则文档，可编辑]
├─ path_rules.md                         [规则文档，可编辑]
└─ README.md                             [总览文档，可编辑]
```

## 权限规则（当前有效）

- 只读可调用目录：`reference_materials/`、`备份/`
- 在只读目录中禁止：修改、replace、重命名、移动、删除
- 其余目录允许：新增、修改、replace、重命名、移动、删除

## 执行口径

- 任何自动化脚本或人工操作，均不得对只读目录执行写操作
- 运行代码时，输入可从只读目录读取；输出必须写入非只读目录
- 清理临时文件、重跑结果、替换中间产物，均在可操作目录完成

## 快速开始

1. 使用 PowerShell 进入仓库根目录：`D:\paper\IJIO_GMM_codex_en`
2. 先进入任务对应目录（例如 `methods/non_hicks/code/`），再运行脚本
3. 将输出写入非只读目录
4. 变更后用 `git status` 检查工作区状态

## 日常开发执行约束（Default permission）

1. 永远在正确的 workspace/repo 里运行任务。
2. 先 Review 再 Apply，先读后改。
3. 改动保持最小化，小步提交，保证可回滚。
4. 不运行重计算、GUI、或高风险命令，除非你明确要求。

## Hard Constraint

- 仅允许修改当前 workspace 内文件；不得触碰 workspace 之外的任何文件。

## 当前工作状态

- **活跃方向**：Non-Hicks 估计（`methods/non_hicks/`）
- **主代码**：`bootstrap1229_group.do`（`methods/non_hicks/code/estimate/`）
- **方法**：GMM Bootstrap 估计，按企业所有权分组
- **网络状态**：GitHub 连接正常 ✓
- **最后同步**：2026-03-05 (fetch/pull 正常)

**详见** → [WORK_LOG.md](WORK_LOG.md)

---

最后更新时间：2026-03-05（实时版本）

