# The ADR process

A specification, plan, task list and implementation for work whose route is understood. Five stages, each gated on the one before it.

Use the ADR process when you know what you are building and roughly how. When you do not know the route — which library, whether a mechanism works at all, what the constraints are — chart it first (see [Cartography](#cartography-is-separate)). The ADR process does not depend on that; it only benefits from the brief it receives.

## Stages

| Stage | Input | Output | Gate to proceed |
|---|---|---|---|
| `specify` | a description, or a brief from a map | `spec.toon` | every requirement cites evidence or is marked `assumption` with what would falsify it |
| `plan` | `spec.toon` | `plan.toon` | no open questions remain: every assumption is resolved, every interface and feasibility question is answered |
| `tasks` | `plan.toon` | `tasks.toon` | each task names the requirement slugs it implements and is independently verifiable |
| `implement` | `tasks.toon` | working code | each task is verified before it is checked in, one commit per task |
| `reflect` | the whole directory | `retro.toon` | learnings are recorded against the process, not just the outcome |

Run `bash ${FIXTURES_DIR}/adr.build.sh adrs/<YYYY-MM-DD>-<feature-slug>` after writing each `.toon`. It validates against the stage's schema and renders the `.md`. Never call `toon` or `check-jsonschema` directly.

## The unknown rule

**A stage does not begin while the previous stage has an open question.** This is the load-bearing rule of the process, and it is internal to the ADR: it holds whether or not a map was ever drawn.

An open question is anything that would change what the next stage writes. Resolve it one of two ways:

- **Research** — check it. Run the command, read the header, apply the profile, query the API. Facts are settled by evidence, never by confidence.
- **Alignment** — ask, when the question is a decision rather than a fact. Run the `align` skill inside the stage that owns the question, and do not leave it until every branch of its tree is answered.

An `assumption` that survives into `tasks.toon` is an open question wearing a costume. If a stage cannot resolve one, it stops and returns the question to its caller with what would settle it. It does not proceed, and it does not soften the wording.

The failure this prevents is specific: a task list serialised against a plan that had not decided how the thing works. The cost lands later as rework, as findings against a spec that was never true, and as a review that has to rediscover the open questions one at a time.

## What each stage owes the next

- `specify` owes **true requirements**: each one evidenced, or explicitly assumed with a falsifier.
- `plan` owes **decisions**: module boundaries, interfaces, data shapes, feasibility, and the reason for each choice. A plan with an unresolved question is not a plan.
- `tasks` owes **verifiable units**: a task a reviewer can check without reading the plan, carrying the slugs it implements.
- `implement` owes **evidence**: the command that proves each task works, run before the commit.

## Cartography is separate

Cartography answers *what is true* and *what did we choose* for work whose destination is known but whose route is not. It lives in `maps/<YYYY-MM-DD>-<slug>/` and ends in a decision, which becomes the brief handed to `adr.specify`.

The dependency runs one way. The map may invoke ADR commands; ADR stages never invoke the map, read its files, or know it exists. When an ADR stage meets an unknown it stops and reports it — whether the caller resolves that by charting, by research, or by deciding is the caller's business.

The two rules look similar and are not: the unknown rule governs **a stage's readiness to advance**; charting governs **whether an ADR is the right instrument at all**.

## Files

```
adrs/<YYYY-MM-DD>-<feature-slug>/
  spec.toon      spec.md
  plan.toon      plan.md
  tasks.toon     tasks.md
  retro.toon     retro.md
  architecture.mmd       (optional, referenced from plan)
  screens/*.wireloom     (optional, referenced from spec or plan)
```

`spec.md`, `plan.md`, `tasks.md` and `retro.md` are generated. Edit the `.toon` and re-run the build script; a hand-edited `.md` is lost on the next render.

## Status

`draft` → `proposed` → `accepted` → `implemented`. A spec becomes `implemented` only when every acceptance criterion has captured evidence in the repository — a command and its output, not a claim. If evidence is missing, the status stays where it is and the missing criteria are listed.
