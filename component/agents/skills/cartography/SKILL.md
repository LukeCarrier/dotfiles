---
name: cartography
description: Chart a course through unknowns as a map of decision tickets, resolve them one at a time with evidence, then hand a cleared frontier to the ADR process. Load when the destination is known but the route is not, when the work needs more than one session, or when a spec would otherwise rest on facts nobody has checked.
license: MIT
compatibility: opencode
---

## What this is

A **map** of decision **tickets**, resolved until the way to the **destination** is clear. The map answers *what is true* and *what we chose*. The ADR process answers *what we will build*. Keep them apart: a map that grows requirements, or an ADR that carries open questions, is a sign the two have been mixed.

Use cartography when the destination is fixed and the route is not — choosing between libraries, proving a mechanism works, filling a gap that would otherwise be guessed at in a spec.

Do not use it when the route is already known. That is an ADR.

## Direction of control

Cartography is the outer process. It invokes the ADR commands; they never invoke it.

```
chart  →  [probe tickets until the frontier is empty]  →  adr.specify → plan → tasks → implement
```

When an ADR stage meets an unresolved claim it **stops and returns the claim** to its caller. It does not chart, probe, or guess. The map owns every unknown; the ADR owns every commitment. A caller that ignores the return value is choosing to guess, and should see that in the output.

## The map

`maps/<YYYY-MM-DD>-<slug>/map.toon`, with evidence beside it under `evidence/`.

```toon
destination: <one line; the outcome this map exists to reach>
created: <YYYY-MM-DD>
tickets[3]{id,question,blockers,state,answer,evidence}:
  T-001,"Does SBPL support a deny on link()?",,answered,"No: sandbox_init rejects file-write-link as an unbound variable",evidence/T-001.md
  T-002,"Does an APFS volume block a cross-volume link?",T-001,open,,
  T-003,"Does cargo build under a baseline without /nix/store?",,answered,"No: dyld aborts on a sibling store path",evidence/T-003.md
```

States are `open`, `probing`, `answered` and `abandoned`. `blocked` is derived from `blockers` and never written by hand.

`map.md` is generated, not authored: `bash ${FIXTURES_DIR}/map.build.sh maps/<YYYY-MM-DD>-<slug>` validates `map.toon` against `map.schema.json` and renders it with `map.jq`. Edit the `.toon` and re-run the script; a hand-edited `.md` is lost on the next render. Never invoke `toon` or `check-jsonschema` directly.

The decision and the ADR directory it spawned live in the same file, as `decision:` and `adr:`. Both are rendered into `map.md`.

Rules:

- A ticket is a question, never a requirement. If it reads like "implement X", it belongs to the ADR.
- `answer` is one line of fact or one line of choice.
- `evidence` is a path under `evidence/` or a citation. An answered ticket with no evidence is still open.
- An unknown discovered while probing spawns a new ticket. The map is allowed to grow; that is the difference between this and a plan.

## The loop

1. **Chart.** Write the destination and the tickets that must be answered to reach it. Invoke the `align` skill when a ticket's framing is unclear. Completion: every ticket is a question, every blocker names another ticket, and the destination is one line.

2. **Take the frontier.** The frontier is every ticket whose blockers are all `answered`. Completion: you have the list, and you have picked the subset that can run at once.

3. **Probe.** One agent per ticket, each in its own worktree. Build the smallest thing that answers the question — a throwaway binary, a script, a reading of primary sources. Record the command and its raw output in `evidence/T-00N.md`. Completion: the evidence file reproduces the answer from a fresh checkout.

4. **Resolve.** Write the one-line answer, mark `answered`, delete the worktree. Completion: no ticket is `answered` without evidence, and no spike branch survives.

5. **Recompute.** Add spawned tickets, recompute blockers, take the new frontier. Render with `map.build.sh` so `map.md` matches the map. Completion: the frontier is empty.

6. **Decide.** Record the chosen direction in `decision`, the ADR directory it spawned in `adr`, and the risks that remain. Completion: a reader follows the answer lines from destination to decision without opening an evidence file.

## Handover to the ADR

The map ends in a decision. Everything after it is the existing ADR process, unchanged, and it knows nothing about this one.

**Conditions.** All must hold before the ADR starts:

- every ticket on the critical path is `answered` with evidence;
- every abandoned ticket states why;
- the decision names a direction and its open risks;
- the map records the ADR directory it spawned.

**What crosses.** A **brief**: the decision, the direction, and the facts the answered tickets established, written as the description handed to `adr.specify`. The ADR receives a brief and nothing else — it is given no tickets, no evidence paths, and no knowledge that a map exists. The map records the link on its own side.

**Why the line matters.** A ticket can be reopened when new evidence arrives. A requirement cannot — it is a commitment the implementation is measured against. Anything still reversible stays on the map; only what has been decided becomes a requirement.

## Research before requirements

`adr.specify` refuses to commit to a claim it cannot establish: it either cites evidence or records an `assumption` with what would falsify it, and when it can do neither it stops and returns the claim to its caller. That duty lives in the ADR stage, because it applies whether or not a map was ever drawn.

This map's job is to make that stopping rare. Every ticket answered is a claim the spec no longer has to invent.
