---
name: code-review
description: Multi-agent code review. Do not read source files yourself. You must dispatch specialised subagents (Archie, Paige, Quest, Scout, Ollie) to examine changes and return structured findings. Load when completing work, receiving feedback, or before claiming completion.
---

## Rules

You MUST follow these rules strictly:

1. **Do NOT read any source files yourself.** Only subagents examine code.
2. **Do NOT analyse code yourself.** You orchestrate; subagents analyse.
3. **Do NOT skip subagents.** Dispatch the required set per the table below.
4. **Do NOT trust agent reports without verification.** Check VCS diff independently.

Violating any rule will dump megabytes of file contents into your context window. Subagents are the only ones who should touch source files.

## When to use me

After completing implementation work that needs structured review. Before merging or claiming completion. When receiving feedback from any source. Do not use for trivial changes.

## Agents

| Agent | Role | Axes |
|-------|------|------|
| Paige | Product Reviewer | completeness, correctness (vs spec) |
| Archie | Architecture Reviewer | structure, clarity, convention |
| Quest | QA Engineer | test-coverage, test-quality |
| Scout | Security Engineer | security |
| Ollie | Operations Engineer | performance, reliability, configuration, observability |

### Dispatch rules

| Scope | Dispatch |
|-------|----------|
| Work covered by a specification (ADR, PRD) | All five |
| Unspecified work (no spec) | Archie, Quest, Scout, Ollie |
| Bug fix only | Quest, Scout |
| Security-sensitive change | Scout mandatory |

## Workflow — execute exactly

### Step 1: Identify scope

Determine: base SHA, head SHA, files changed, reference spec URI (if any).

### Step 2: Dispatch subagents

For each agent in the required set, invoke the Task tool once with:
- `description`: brief label like "Archie architecture review"
- `prompt`: the dispatch prompt below, filled in
- `subagent_type`: the agent name in lowercase (archie, paige, quest, scout, ollie)

Dispatch all required agents. Do not wait for one to finish before dispatching the next.

#### Dispatch prompt template

```
You are {agent name} ({role}).

Your axes: {axes}

Scope:
- Base SHA: {sha}
- Head SHA: {sha}
- Files changed: {paths}
- Reference spec: {uri} (omit if none)

Examine every changed file. For each finding, return one row in TOON tabular format:

findings[N]{id,axis,severity,location,observed,expected,impact,recommendation}:
  <id,axis,severity,code://path:line,observed,expected,impact,recommendation>

Use the code:// scheme for locations. Use stable slugs in id, never section numbers. Return only the TOON block above — no preamble, no commentary, no markdown. Do not modify any files.
```

### Step 3: Await all responses

Wait for every dispatched subagent to complete. Collect their TOON output.

### Step 4: Merge findings

1. Collect all finding rows from all subagents
2. Deduplicate by (axis, location, observed) — same axis, same location, same observed behaviour
3. On conflict: keep highest severity, list all reporting agents
4. Group by axis for presentation

### Step 5: Write consolidated document

Write to `.agents/forge/code-review/<run-id>/consolidated.toon`:

```toon
review:
  runId: <run-id>
  scope:
    referenceIds[1]: spec://...
    baseSha: <sha>
    headSha: <sha>
    filesChanged[N]: <path1>,<path2>,...

findings[N]{id,axis,severity,location,observed,expected,impact,recommendation}:
  <merged findings>

agents[N]{name,role,findingsCount}:
  <each subagent>
```

### Step 6: Generate report

Do NOT summarise or format the findings yourself. Instead, run the report script:

```bash
report.sh .agents/forge/code-review/<run-id>/consolidated.toon > .agents/forge/code-review/<run-id>/report.md
```

The script validates the TOON and emits a markdown report with summary table and per-finding details. Show the user the path to the report.

## Findings schema

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Canonical identifier; stable slug, not structural position |
| `axis` | yes | One of: completeness, correctness, security, test-coverage, test-quality, structure, clarity, convention, performance, reliability, configuration, observability |
| `severity` | yes | critical, high, medium, low, info |
| `location` | yes | `code://<path>[:<line>]` |
| `observed` | yes | What the code actually does |
| `expected` | yes | What it should do; semantic description, no numbered references |
| `impact` | yes | Consequence now, consequence if deferred |
| `recommendation` | yes | Concrete fix suggestion |
| `externalId` | no | Tool-resolvable URL (GitHub blob, Confluence page) |
| `externalReferences[N]{id,externalId}` | no | Related references |

### Canonical addresses

```
code://src/auth.rs:142                          — file:line
spec://adrs/2024-01-foo#requirement.rate-limit  — spec item by slug
dep://npm/packages/frontend/prod/lodash@^4.17   — dependency path
```

`id` uses canonical addresses for dedup. `externalId` holds a tool-resolvable URL for tools that cannot interpret the scheme.

## Anti-patterns

- No performative agreement: "You're absolutely right", "Great point", "Thanks for"
- No implementation before verification against the codebase
- No completion claims without running verification commands
- No numbered section references in `expected` — use stable slugs from `id`
