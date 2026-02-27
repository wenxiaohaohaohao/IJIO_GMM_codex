# AGENTS.md

## Purpose

Project-specific instructions for Codex in this workspace.

## Workspace context

- This folder contains research materials (data files, drafts, figures, and scripts).
- Treat data files (e.g., .dta, .zip) as immutable unless the user explicitly asks to modify or regenerate them.

## Editing guidelines
- Keep edits minimal and localized; do not reformat entire documents.
- Preserve existing line breaks in text/LaTeX files unless the change requires otherwise.
- Prefer creating new files over overwriting outputs; place generated tables/figures in the user-specified folder (or `figures/` if none).

## Execution guidelines
- Use `rg` for searching where possible.
- Avoid long-running or compute-heavy commands without asking first.
- Do not run Stata or other GUI/interactive tools unless explicitly requested.

## Communication
- Respond in the user's language (Chinese when the user writes in Chinese).
- Call out any ambiguous requests and ask before making risky changes.

## Daily Development Constraints (Default permission)
1. Always run tasks in the correct workspace/repo.
2. Review before Apply: read first, then edit.
3. Keep changes minimal; use small, reversible commits.
4. Do not run heavy computation, GUI tools, or high-risk commands unless explicitly requested by the user.

## Hard Constraint
- Only modify files in this workspace; do not touch anything outside.

