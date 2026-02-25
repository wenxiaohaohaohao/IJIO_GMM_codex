# Workflow

This folder provides a reproducible research workflow with consistent inputs, scripts, logs, and outputs.

## Quick start
1. Set tool paths in `config/tools.ps1`.
2. Put raw data in `data/raw`.
3. Run `scripts/run_all.ps1` from PowerShell.

## Structure
- data/raw: immutable inputs
- data/processed: intermediate data
- src/: analysis scripts by language
- output/tables, output/figures: final artifacts
- output/runs/<timestamp>: per-run logs

## Notes
- The runner skips tools that are not configured.
- Edit templates in `src/` for your project.

## Daily Dev Defaults
- SOP: `DAILY_DEV_DEFAULT.md`
- Preflight check: `scripts/dev_preflight.ps1`
- Small-step commit helper: `scripts/dev_commit.ps1`
- Prompt template: `templates/codex_default_prompt.txt`

## GitHub Research Templates
- Overall flow and branch policy: `GITHUB_RESEARCH_FLOW_TEMPLATE.md`
- Per-round estimation log template: `ESTIMATION_ROUND_LOG_TEMPLATE.md`
- PR template: `.github/PULL_REQUEST_TEMPLATE.md`
- Issue templates:
  - Experiment round: `.github/ISSUE_TEMPLATE/experiment_round.md`
  - Bug/regression: `.github/ISSUE_TEMPLATE/bug_regression.md`

Recommended usage order:
1. Create branch by `GITHUB_RESEARCH_FLOW_TEMPLATE.md`.
2. Run one estimation round and fill `ESTIMATION_ROUND_LOG_TEMPLATE.md`.
3. Open an issue from `experiment_round.md` (or `bug_regression.md`).
4. Open PR with `.github/PULL_REQUEST_TEMPLATE.md` and link the issue.
