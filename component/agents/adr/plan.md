---
status: draft
created: 2026-01-21
updated: 2026-01-21
author: Luke Carrier
---

# `adr.plan`

Create a technical plan in TOON format. This must happen after `specify`.

## Usage

```
/adr.plan <feature-slug> [constraints...]
```

## Process

1. Read `adrs/<YYYY-MM-DD>-<feature-slug>/spec.toon` to understand the requirements.
2. Determine the appropriate implementation approach and architecture.
3. Write the plan to `adrs/<YYYY-MM-DD>-<feature-slug>/plan.toon` with the TOON schema below.
4. Validate: `toon --decode adrs/<YYYY-MM-DD>-<feature-slug>/plan.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/plan.schema.json /dev/stdin`. Fix any validation errors.
5. Run `bash ${FIXTURES_DIR}/build.sh adrs/<YYYY-MM-DD>-<feature-slug>` to generate `plan.md`.

## TOON Schema

```toon
title: <Human-readable title>
status: draft
created: <YYYY-MM-DD>
author: <name>
approach: <high-level approach>
architecture: <architecture overview>
technologies[N]{name,role}:
  <name>,<role>
components[N]{name,purpose,details}:
  <name>,<purpose>,<details>
dataFlow: <optional data flow description>
deployment: <optional deployment considerations>
```

### Diagrams

Reference external Mermaid `.mmd` files in any free-text field (e.g., `architecture`, `dataFlow`) using the `{{mermaid: <file>}}` syntax:

```toon
architecture:
  {{mermaid: architecture.mmd}}
```

Place the `.mmd` file alongside the `.toon` file. At build time, `build.sh` inlines the Mermaid source as a ` ```mermaid ` code block — no pre-rendering or external tooling required.

## Output

- `adrs/<YYYY-MM-DD>-<feature-slug>/plan.toon` — structured plan in TOON
- `adrs/<YYYY-MM-DD>-<feature-slug>/plan.md` — human-readable markdown (generated)
