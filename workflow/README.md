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
- Preflight check: `scripts/dev_preflight.ps1`
- Small-step commit helper: `scripts/dev_commit.ps1`
- Prompt template: `templates/codex_default_prompt.txt`
