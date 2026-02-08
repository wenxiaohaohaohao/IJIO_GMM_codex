# 日常开发（Default Permission）SOP

适用场景：90% 日常修改任务。

## 1) 永远在正确的 workspace/repo 里跑任务

先执行：

```powershell
powershell -ExecutionPolicy Bypass -File workflow/scripts/dev_preflight.ps1
```

该脚本会检查：
- 当前目录是否在工作区内
- 当前目录是否是 git 仓库
- 当前改动概览（如已是 git 仓库）

## 2) 先 Review 再 Apply

推荐顺序：
1. `rg` 搜索目标文件和关键路径
2. 只读查看文件（`Get-Content`）
3. 明确最小改动范围
4. 再执行编辑
5. 编辑后再做一次静态复查

## 3) 小步提交（可回滚）

每次改动尽量控制在一个小主题内，建议 1-5 个文件。

提交命令：

```powershell
powershell -ExecutionPolicy Bypass -File workflow/scripts/dev_commit.ps1 -Message "feat: your small change"
```

## 4) 固定 Prompt 约束语句

在每次任务 Prompt 中包含这句：

`Only modify files in this workspace; do not touch anything outside.`

可直接复制模板：

`workflow/templates/codex_default_prompt.txt`
