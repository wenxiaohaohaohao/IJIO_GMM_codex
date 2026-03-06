# 工作日志

工作进度、问题追踪、结果更新的详细记录。

---

## 2026-03-05

### 工作内容
- **网络与环境排查**
  - GitHub 连接异常（400 status, invalid token）：已解决 ✓
  - 网络连接测试：`Test-NetConnection github.com -Port 443` 通过
  - Git fetch 恢复正常：`git fetch origin main` 执行成功

- **工作区整理与文档更新**
  - 定位主代码文件：`methods/non_hicks/code/estimate/bootstrap1229_group.do`
  - 更新 README.md 文件结构说明，补充三种估计方法子目录详情
  - 新增"当前工作状态"章节，记录活跃方向与同步状态
  - 创建 WORKFLOW_MASTER.md 工作流总纲
  - 创建 WORK_LOG.md 工作日志

- **M0 中间品链路审计**
  - **M0.1 完成** ✅：主代码口径锁定
    - `m = ln(delfateddomestic)`（已平减国内中间投入）
    - 发现 `domesticint ≠ delfateddomestic` 口径差异
    - `m` 未被 winsorize（而 lnR/lnM 被 winsor at 1/99）
    - 外部数据依赖：junenewg_0902.dta, Brandt-Rawski deflator, firm_year_IVs
  - **M0.2 完成** ✅：一阶段代码抽取
    - 确认一阶段在主代码同文件（L199-L211）
    - Cost share → `es`, `shat`; φ回归 → `phi`, `epsilon`
  - **尹恒替代口径分析完成** ✅
    - 来源：Gauss代码 GMM_ind*.prg L182-186
    - 核心差异：全口径含进项税 + 行业投入价格指数 vs 主代码仅国内投入已预平减

### 主要发现
- **⚠ 潜在口径不一致**：一阶段cost share用`lnM=ln(domesticint)`未平减，二阶段用`m=ln(delfateddomestic)`已平减
- 尹恒口径与主代码在中间品范围、平减方式、资本构建方面有系统性差异

### 待办事项
- [x] M0.1：主代码口径锁定 ✅
- [x] M0.2：抽取一阶段代码 ✅
- [ ] M0.3：兼容性对照表 - 需数据层面验证 domesticint vs delfateddomestic
- [ ] M0.4：样本差异分解
- [ ] M0.5：诊断回归脚本
- [ ] M0.6：运行敏感性 A/B/C 方案
- [ ] M0.7：整理所有产出文档

---

## 2026-02-27

### 工作内容
- **初期 GitHub 认证问题排查**
  - Copilot MCP server 连接失败：`400 status connecting to https://api.githubcopilot.com/mcp`
  - 原因：认证令牌格式不正确（missing = param）
  - 建议方案：重新登录、清除缓存、重启 VS Code

---

## 操作指南

### 如何添加日志条目
在对应日期下添加：
```markdown
## YYYY-MM-DD

### 工作内容
- 具体工作项目 1
- 具体工作项目 2

### 主要发现
- 发现 1
- 发现 2

### 待办事项
- [ ] 任务 1
- [ ] 任务 2
```

### 简洁更新规则
- **详细内容** → 本文件（WORK_LOG.md）
- **摘要信息** → README.md 中的"当前工作状态"章节
- **规则变更** → AGENTS.md 中的对应章节

