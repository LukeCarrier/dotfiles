---
status: draft
created: 2026-01-21
updated: 2026-01-21
author: Luke Carrier
---

# `adr.implement`

Execute an ADR implementation. This must happen after `tasks`.

## Usage

```
/adr.implement <feature-slug>
```

## Process

1. Read `adrs/<YYYY-MM-DD>-<feature-slug>/tasks.toon` to get the task list.
2. Work through each task sequentially.
3. As each task is completed, update its title in `tasks.toon` by prefixing with `[x]`.
4. Run `bash ${FIXTURES_DIR}/adr.build.sh adrs/<YYYY-MM-DD>-<feature-slug>` to regenerate the markdown.
5. If a task is blocked or unclear, ask the user for clarification rather than guessing.
6. When all tasks are complete, update `spec.toon` status from `draft` to `implemented` and re-render.

## Output

- Completed implementation of the ADR
- Updated `tasks.toon` with `[x]` markers on completed items
- Updated `spec.toon` status to `implemented`
- All `.md` files regenerated via render script
