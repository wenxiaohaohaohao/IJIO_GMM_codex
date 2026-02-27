# PATH_RULES

## Scope

- Workspace root: `D:\paper\IJIO_GMM_codex_en`
- These rules apply to code search, reading, editing, and reporting in this project.

## Mandatory Path Rules

1. Use absolute paths only.
2. Before any substantive action, echo:
   - workspace root
   - target file absolute path(s)
3. Never use files under backup-like paths as the primary code basis (for example: `archive/`, `backup/`, or `备份/`).
4. If duplicate filenames exist, lock to the explicit primary absolute path before analysis or edits.
5. For clickable file links, use absolute-path form `/D:/...` (not relative or ambiguous forms).

## Permission Consistency

1. Read-only callable directories:
   - `D:\paper\IJIO_GMM_codex_en\reference_materials\`
   - `D:\paper\IJIO_GMM_codex_en\备份\`
2. In read-only directories, do not modify, replace, move, rename, or delete files.
3. Outside read-only directories, edits are allowed under user instructions.

## Markdown Check Policy

1. Do not scan all `.md` files before every answer by default.
2. Always check project instruction files relevant to execution, especially:
   - `D:\paper\IJIO_GMM_codex_en\AGENTS.md`
   - `D:\paper\IJIO_GMM_codex_en\path_rules.md`
3. Check additional `.md` files only when:
   - explicitly requested by the user, or
   - required by the current task context.

## Change Safety

1. Keep edits minimal and localized.
2. Do not modify data files unless explicitly requested.
