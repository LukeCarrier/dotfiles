---
name: writing-skills
description: How to write documents agents consume. Load when creating or editing a skill, an agent definition, or an AGENTS.md.
---

Reference for writing anything an agent reads to decide *how to act*: a skill, an agent definition, an `AGENTS.md`. The packaging differs; the writing does not. The goal is a **predictable process** — the agent taking the same path every run — not identical output.

## Context pointers

A **context pointer** names out-of-context material and encodes the condition for reaching it. A skill's `description` is one. A line in `AGENTS.md` naming a doc is the same object. The pointer's *wording*, not its target, decides when and how reliably the agent reaches the material. A must-reach target behind a weak pointer is a variance bug: sharpen the wording first; inline the material only if sharpening fails.

A pointer does two jobs — state what the material is, and list the **branches** that trigger reaching it (a branch is a distinct case the document handles). Every word of an always-loaded pointer costs on every turn, so prune it harder than the body:

- **Front-load the trigger word** — the pointer does its work at its start.
- **One trigger per branch.** Synonyms renaming one branch are one branch written twice; keep only genuinely distinct branches.
- **Cut identity the body already carries.**

## The two loads

Everything you add spends one of two budgets:

- **Context load** — always-loaded material on the agent's window: an `AGENTS.md` line, a skill description, anything present every turn, spending tokens and attention whether or not it fires.
- **Cognitive load** — the cost on you: knowing which documents exist and when to reach for each. You are the index. Not a cost to minimise — it's the price of your agency; spend it where your judgement matters, remove it where it doesn't.

Material reached only through a pointer escapes context load at the cost of the pointer's own line.

## Information hierarchy

A document mixes two content types — **steps** (ordered actions the agent performs) and **reference** (facts and rules consulted on demand). The core decision is where each piece sits on the ladder, ranked by how immediately it's needed:

1. **In-file step** — the primary tier: what the agent does, in order.
2. **In-file reference** — consulted on demand. Often a legitimately flat peer-set (every rule of a review on one rung) — fine, not a smell.
3. **Disclosed reference** — pushed to a separate file behind a pointer, loaded only when the pointer fires.

Push too little down and the top bloats; push too much and you hide material the agent needs. That tension is the decision.

**Progressive disclosure** is the move down the ladder so the top stays legible. Branching is the cleanest test: inline what every branch needs, disclose what only some branches reach.

**Co-location** is the within-file companion: keep a concept's definition, rules, and caveats under one heading, so reading one part brings its neighbours. The document should read like documentation written for the agent.

**Sprawl** is the failure mode: a document too long even when every line is live. Attention thins across the excess. The cure is the ladder — disclose reference, split by branch or sequence.

## Steps and completion criteria

Every step ends on a **completion criterion** — the condition telling the agent the work is done. Two properties make it a lever:

- **Clarity** — can the agent tell done from not-done? A vague bound ("understanding reached") invites **premature completion**: ending early, attention slipping to *being done*. Sharpen the bound first; only if it's irreducibly fuzzy *and* you see the rush, split the sequence to hide the later steps — and hiding only works across a real context boundary (a hand-off or subagent dispatch; an inline call clears nothing).
- **Demand** — how much it requires. "Every modified module accounted for" forces thorough work where "produce a change list" does not.

The strongest criteria are both checkable and exhaustive.

## Leading words

A **leading word** is a compact concept already in the model's pretraining that the agent thinks with while running the document (*lesson*, *tracer bullet*, *tight loop*). Repeated as a token — never spelled out as a sentence each time — it anchors a whole region of behaviour in few tokens by recruiting priors the model already holds. Coining your own works only if you define it clearly; a made-up word recruits no priors.

Hunt for restatements a leading word retires:

- "fast, deterministic, low-overhead" → *tight* (a *tight* loop).
- "a loop you believe in that goes red on the bug" → *red*.

**Negation** is the failure mode beside this: steering by prohibition drags the forbidden behaviour into context and makes it *more* available. Prompt the **positive** — state the target behaviour so the banned one is never spoken. A prohibition earns its place only as a hard guardrail you can't phrase positively; even then, pair it with the positive target.

## Pruning

- **Single source of truth**: one authoritative place per meaning, so changing behaviour is a one-place edit. **Duplication** costs maintenance and tokens and inflates a meaning's rank on the ladder.
- **The environment is a source of truth too** — config files, task-runner scripts, `--help` output, directory layout. A document restating it is a **cache**, earning its load only when the lookup is expensive. Cache what the agent can't find by looking (unwritten conventions, the reason behind a choice, the gotcha no config confesses); leave one-command lookups to the environment.
- **Relevance**: every line must still bear on what the document does. Lines lose relevance by never bearing on the task, or by going stale as the world changes. Without pruning, the default fate is **sediment** — stale layers that settle because adding feels safe and removing feels risky.
- **No-ops**: an instruction the model already obeys by default pays load to say nothing. The test — does it change behaviour versus the default? — is model-relative; settle disagreements by running the document, not debating. When a sentence fails, delete the whole sentence.

## Skill mechanics

What changes when the document is a skill in this repo. Skills live at `component/agents/skills/<name>/SKILL.md` and are installed into each harness by the Nix plumbing (`config.agents.skills`). The interchange format between agents is TOON; multi-agent work dispatches the named roster (Archie, Ollie, Paige, Quest, Scout).

- **Frontmatter**: `name` and `description` are required. The `description` is the skill's top-level context pointer — apply the pointer-writing rules above in full. It's permanently loaded, so it earns the hardest pruning.
- **Reach**: a skill's reachability is driven by which agent definitions point at it and how the harness installs it — not by a plugin flag. A skill needed by several agents is one home for shared reference; put reference many skills need in one skill and have the others point at it.
- **Splitting**: split off a separate file only when a distinct trigger branch or an independent reach earns the new always-loaded pointer. A short companion that carries no independent trigger belongs folded in.

## Shifting shared language up

When several skills repeat the same rule, tone, or vocabulary, that repetition is duplication paying context load in every skill. If the shared material is *about how an agent behaves*, lift it into the relevant **agent definition** (its system prompt) — the single source of truth for that agent's standing behaviour — and let skills assume it. Reserve skills for the procedure; let the agent definition carry the disposition.
