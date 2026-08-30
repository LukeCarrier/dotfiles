---
status: draft
created: 2026-01-21
updated: 2026-01-21
author: Luke Carrier
---

# `adr.reflect`

Write a retrospective in TOON format. This is an optional final step after implementation.

## Usage

```
/adr.reflect <feature-slug>
```

## Process

1. Read `adrs/<YYYY-MM-DD>-<feature-slug>/spec.toon`, `plan.toon`, and `tasks.toon`.
2. Reflect on what went well, what didn't, and what could be improved.
3. Write the retrospective to `adrs/<YYYY-MM-DD>-<feature-slug>/retro.toon` with the TOON schema below.
4. Validate: `toon --decode adrs/<YYYY-MM-DD>-<feature-slug>/retro.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/retro.schema.json /dev/stdin`. Fix any validation errors.
5. Run `bash ${FIXTURES_DIR}/adr.build.sh adrs/<YYYY-MM-DD>-<feature-slug>` to generate `retro.md`.

## TOON Schema

```toon
title: <Human-readable title>
status: draft
created: <YYYY-MM-DD>
author: <name>
wentWell[N]:
  - <what went well>
wentBadly[N]:
  - <what didn't go well>
improvements[N]:
  - <process improvement>
```

## Output

- `adrs/<YYYY-MM-DD>-<feature-slug>/retro.toon` — structured retrospective in TOON
- `adrs/<YYYY-MM-DD>-<feature-slug>/retro.md` — human-readable markdown (generated)
