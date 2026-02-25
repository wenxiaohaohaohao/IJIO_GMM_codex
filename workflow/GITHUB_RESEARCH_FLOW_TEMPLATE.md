# GitHub Research Workflow Template

## A. Branch Naming Convention
Use one branch per objective. Recommended patterns:

- `feat/model-<short-topic>`: structural/model changes
- `exp/iv-<set>-<group>-<date>`: experiment rounds (IV/spec tests)
- `docs/paper-<section>`: paper text or notes
- `fix/<bug-short-tag>`: bug fixes
- `chore/workflow-<topic>`: non-model engineering cleanup

Examples:
- `exp/iv-a2-g2-430fix-20260226`
- `feat/hard-linked-constraint-v1`
- `docs/wenxiao-method-section5`

## B. Pull Request Policy
- Keep one PR = one research objective.
- PR must include: equation impact, IV impact, result deltas, and reproducibility command.
- Do not mix model changes and bulk file cleanup in one PR.

## C. Issue Types
- `Experiment Round`: each estimation round gets one issue.
- `Bug / Regression`: each failure mode (e.g., `r(430)`, path failure) gets one issue.

## D. Estimation Round Logging Standard
For each round, record at least:

- Metadata: branch, commit, datetime, objective
- Spec: equation version, IV set, groups, run switches
- Outputs: logs, point estimates, elasticity, IV diagnostics
- Results: `gmm_conv`, `J_opt`, `J_p`, key elasticities, negative-share
- Decision: accept / robustness-only / reject
- Next action

Use template issue: `.github/ISSUE_TEMPLATE/experiment_round.md`

## E. Minimal Review Gate (before merge)
- Point estimation runnable on target groups
- Main diagnostics readable and archived
- Baseline vs current comparison documented
- No unintended data-file edits

## F. Suggested Weekly Cadence
- Monday: define experiment issues and branch plan
- Tue-Thu: run rounds and fill experiment issues
- Friday: PR review + merge only validated branches

## G. Fixed Naming Fields (Required)
Use the following field formats in issue/PR/log records:

- `RUN_TAG`: `YYYYMMDD_HHMMSS` (example: `20260226_093015`)
- `IV_SET`: one of `A/B/C/A1/A2/A3`
- `TARGET_GROUP`: `ALL | G1_17_19 | G2_39_41`
- `commit`: full SHA preferred (at least first 8 chars if shortened)

## H. Acceptance Thresholds (Project Gate)
For a round to enter mainline candidates, all must hold:

- `gmm_conv == 1`
- `J_p` not at extreme boundary (avoid persistent near-0 failures)
- Key elasticities economically reasonable (no systematic sign reversal)
- Negative-share diagnostics acceptable for key elasticities (project-specific tolerance)

If any condition fails: mark round as `Robustness only` or `Reject`.

## I. Main-Code White List
By default, only edit the following core files for estimation-system changes:

- `1017/1022_non_hicks/code/estimate/bootstrap1229_group.do`
- `1017/1022_non_hicks/code/master/Master_Non_hicks.do`
- `1017/1022_non_hicks/code/master/run_step1_point_diag.do`
- `1017/1022_non_hicks/code/master/run_group_G1.do`
- `1017/1022_non_hicks/code/master/run_group_G2.do`

Avoid editing backup/history scripts unless explicitly required and documented in PR.
