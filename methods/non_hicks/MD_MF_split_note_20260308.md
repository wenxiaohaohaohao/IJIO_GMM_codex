# MD/MF Split Note (2026-03-08)

当前主代码文件：
- [bootstrap1229_group.do](d:/paper/IJIO_GMM_codex_en/methods/non_hicks/code/estimate/bootstrap1229_group.do)

当前 G1 主结果文件：
- [gmm_point_group_G1_17_19.dta](d:/paper/IJIO_GMM_codex_en/methods/non_hicks/data/work/gmm_point_group_G1_17_19.dta)
- [elasticity_group_G1_17_19.dta](d:/paper/IJIO_GMM_codex_en/methods/non_hicks/data/work/elasticity_group_G1_17_19.dta)

## 口径

按照 `wenxiao_0308` 的理论，硬联立参数 `b_m` 对应总中间品弹性 `alpha_m`，并满足：

\[
S^{FD}_{ft} = 1 - \frac{1}{\alpha_m} e^{-\hat s^R_{ft}}
\]

\[
\theta^{RD}_{ft} = \alpha_m (1 - S^{FD}_{ft}), \qquad
\theta^{RF}_{ft} = \alpha_m S^{FD}_{ft}
\]

代码中：
- `m = ln(delfateddomestic)` 保持不变
- `b_m = b_amc` 的硬联立保持不变
- 新增了国内/国外中间品弹性拆分输出

## raw 与 clipped

当前同时输出两套拆分：

1. `raw`
- 直接按理论公式计算 `S_fd_hat`
- 不对 `S_fd_hat` 做 `[0,1]` 截断

2. `clipped`
- 仅用于报告
- 将 `S_fd_hat` 截断为：
  - `S_fd_clip = 0` if `S_fd_hat < 0`
  - `S_fd_clip = 1` if `S_fd_hat > 1`
  - 否则 `S_fd_clip = S_fd_hat`

对应的弹性为：
- `theta_md_clip_hat = b_m * (1 - S_fd_clip)`
- `theta_mf_clip_hat = b_m * S_fd_clip`

注意：
- `clipped` 只改变报告层拆分
- 不改变 GMM 目标函数
- 不改变点估参数

## b_es 的解释

`b_es` 现在只是兼容旧脚本的别名：
- `b_es = b_amc`
- `b_essq = b_as`

它不是单独的经济参数，不应再解释为“国外中间品弹性”。

## 当前 G1 结果

当前主结果：
- `b_m = 0.59197`
- `elas_k_mean = 0.09839`
- `elas_l_mean = 0.17943`
- `elas_m_mean = 0.59197`

raw 拆分：
- `sfd_mean = 0.13276`
- `elas_md_mean = 0.51339`
- `elas_mf_mean = 0.07859`
- `sfd_negshare = 0.23406`
- `elas_mf_negshare = 0.23406`

clipped 拆分：
- `sfd_clip_mean = 0.19769`
- `elas_md_clip_mean = 0.47495`
- `elas_mf_clip_mean = 0.11703`
- `elas_md_clip_negshare = 0`
- `elas_mf_clip_negshare = 0`

## 解读

当前样本下，`raw S_fd_hat` 有约 `23.4%` 的观测小于 0，所以 raw 的国外中间品弹性也会出现同样比例的负值。

如果目标是：

1. 忠实呈现理论公式原始输出
- 看 `raw`

2. 给论文正文或表格报告更稳健、可解释的拆分
- 看 `clipped`

目前建议：
- 参数估计和约束判断继续看 `raw`
- 论文展示和经验解释优先看 `clipped`
