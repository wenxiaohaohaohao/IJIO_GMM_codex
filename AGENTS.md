# AGENTS.md

## Purpose

Project-specific operating rules for Codex in this workspace.

## Workspace Scope

- Workspace root: `D:\paper\IJIO_GMM_codex_en`
- This folder contains research materials (data files, drafts, figures, and scripts).
- Treat data files (for example `.dta` and `.zip`) as immutable unless the user explicitly requests regeneration.

## Permission Model

- Read-only callable directories: `reference_materials/` and `备份/`
- Mutable directories: all other paths in this workspace
- In read-only directories: do not modify, replace, move, rename, or delete files

## Editing Rules

- Keep edits minimal and localized; do not reformat entire documents.
- Preserve existing line breaks in text and LaTeX files unless the task requires changes.
- Prefer creating new files over overwriting outputs.
- Place generated tables/figures in the user-specified folder (or `figures/` if unspecified).

## Execution Rules

- Always run commands in the correct workspace/repo.
- Review before apply: read first, then edit.
- Use `rg` for searching whenever possible.
- Avoid long-running or compute-heavy commands unless explicitly approved.
- Do not run GUI or interactive tools (for example Stata UI) unless explicitly requested.
- Keep changes small and reversible.
- For troubleshooting requests, stop after identifying the primary cause and applying the minimal local fix.
- Do not keep retrying or expanding scope once the main blocker is clear unless the user asks for deeper investigation.
- If the issue depends on files outside this workspace, explain the boundary clearly and ask the user for the relevant content instead of continuing to probe.

## Communication

- Respond in the user's language (Chinese when the user writes in Chinese).
- Call out ambiguities and ask before risky actions.

## Hard Constraint

- Only modify files inside this workspace. Never touch files outside it.
