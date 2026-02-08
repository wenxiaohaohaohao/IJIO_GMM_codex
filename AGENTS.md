# AGENTS.md

## Purpose

Project-specific instructions for Codex in this workspace.

## Workspace context

- This folder contains research materials (data files, drafts, figures, and scripts).
- Treat data files (e.g., .dta, .zip) as immutable unless the user explicitly asks to modify or regenerate them.

## Editing guidelines
- Keep edits minimal and localized; do not reformat entire documents.
- Preserve existing line breaks in text/LaTeX files unless the change requires otherwise.
- Prefer creating new files over overwriting outputs; place generated tables/figures in the user-specified folder (or `图表/` if none).

## Execution guidelines
- Use `rg` for searching where possible.
- Avoid long-running or compute-heavy commands without asking first.
- Do not run Stata or other GUI/interactive tools unless explicitly requested.

## Communication
- Respond in the user's language (Chinese when the user writes in Chinese).
- Call out any ambiguous requests and ask before making risky changes.
