---
status: draft
created: 2026-10-31
author: Luke Carrier
---

# `chart`

Open a map of decision tickets for a piece of unknown work. This is the entry point to the cartography process, which sits above the ADR process and decides when an ADR is written.

## Usage

```
/chart <feature-slug> [question ...]
```

## Process

1. Load the `cartography` skill.
2. Read `maps/<YYYY-MM-DD>-<feature-slug>/map.toon` if it exists; continue from its frontier. Otherwise create it.
3. State the destination in one line. Invoke the `align` skill to settle any question whose framing is unclear — a badly framed ticket is expensive, because it gets probed.
4. Write the tickets standing between the destination and what is already known. Seed them from the questions given and from what the map is missing.
5. Resolve tickets: dispatch one agent per ticket on the frontier, each in its own worktree, and record evidence under `evidence/` before writing the answer.
6. Render: run `bash ${FIXTURES_DIR}/map.build.sh maps/<YYYY-MM-DD>-<feature-slug>`. It validates `map.toon` against `${FIXTURES_DIR}/map.schema.json` and writes `map.md`. Fix anything it reports and run it again. Never invoke `toon` or `check-jsonschema` yourself: neither is on `PATH`.
7. When the frontier is empty and the decision is recorded, hand over by running `adr.specify` with the same feature slug.

## Output

- `maps/<YYYY-MM-DD>-<feature-slug>/map.toon` — destination, tickets and state
- `maps/<YYYY-MM-DD>-<feature-slug>/map.md` — human-readable rendering (generated)
- `maps/<YYYY-MM-DD>-<feature-slug>/evidence/T-00N.md`

## Direction of control

This command may invoke the ADR commands. The ADR commands never invoke this one. If `adr.specify` or `adr.plan` finds an unresolved claim, it stops and returns the list to its caller — the map decides whether that becomes a ticket.
