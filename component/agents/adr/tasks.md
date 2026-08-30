---
status: draft
created: 2026-01-21
updated: 2026-01-21
author: Luke Carrier
---

# `adr.tasks`

Break an ADR plan into concrete tasks in TOON format. This must happen after `plan`.

## Usage

```
/adr.tasks <feature-slug>
```

## Process

1. Read `adrs/<YYYY-MM-DD>-<feature-slug>/plan.toon` to understand the full plan.
2. Read `adrs/<YYYY-MM-DD>-<feature-slug>/spec.toon` to reference requirement slugs.
3. Break the plan into concrete, independently implementable tasks.
4. Each task MUST reference the spec slug(s) it implements in its `refs` field.
5. Write the tasks to `adrs/<YYYY-MM-DD>-<feature-slug>/tasks.toon` with the TOON schema below.
6. Validate: `toon --decode adrs/<YYYY-MM-DD>-<feature-slug>/tasks.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/tasks.schema.json /dev/stdin`. Fix any validation errors.
7. Run `bash ${FIXTURES_DIR}/adr.build.sh adrs/<YYYY-MM-DD>-<feature-slug>` to generate `tasks.md`.

## TOON Schema

```toon
title: <Human-readable title>
status: draft
created: <YYYY-MM-DD>
author: <name>
items[N]{id,title,description,criteria,complexity,effort,dependencies,refs}:
  T-<M>,<Title>,<description>,<success criteria>,low|medium|high,<effort estimate>,<comma-separated dep IDs>,<comma-separated spec slugs>
```

### Field reference

| Field | Description |
|-------|-------------|
| `id` | Task identifier: `T-001`, `T-002`, etc. |
| `title` | Short task name |
| `description` | What to implement |
| `criteria` | How to verify completion |
| `complexity` | low, medium, or high |
| `effort` | Time estimate (e.g. "2-4h") |
| `dependencies` | Comma-separated task IDs this depends on, or empty |
| `refs` | Comma-separated spec requirement slugs this implements |

The `refs` field is the traceability link. Paige uses it to verify completeness.

## Output

- `adrs/<YYYY-MM-DD>-<feature-slug>/tasks.toon` — structured tasks in TOON
- `adrs/<YYYY-MM-DD>-<feature-slug>/tasks.md` — human-readable markdown (generated)
