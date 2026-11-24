---
name: code-review
description: Multi-agent code review. Orchestrate without reading source; prepare revision-specific inputs for Archie, Paige, Quest, Scout, and Ollie to examine. Load when completing work, receiving feedback, or before claiming completion.
---

## Rules

You MUST follow these rules strictly:

1. **Do NOT read any source files yourself.** Only subagents examine code.
2. **Do NOT analyse code yourself.** You orchestrate; subagents analyse.
3. **Do NOT skip subagents.** Dispatch the required set per the table below.
4. **Do NOT trust agent reports without verification.** Check VCS diff independently.

Violating any rule will dump megabytes of file contents into your context window. Subagents are the only ones who should touch source files.
Reviewers can use read, glob, and grep, but cannot run shell or Git commands or edit files. Shell access would permit unsupervised command execution and is a security boundary, not a permission to request or bypass. The orchestrator supplies the diff and all other context reviewers need; do not ask reviewers to run Git or assume a revision is checked out.

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

Determine: base SHA, head SHA or working-tree state, files changed, reference spec URI (if any). Include untracked files when they are in scope; do not silently treat a committed diff as the working tree.

### Step 2: Prepare review inputs

Create a new run directory under `.agents/forge/code-review/<run-id>/`. Write the complete scoped VCS diff to a file there without loading it into your context. Git diffs omit untracked files: list any in-scope untracked files as additions and provide their contents in the snapshot. Make the exact head-version source and relevant tests available at a filesystem path: use the working tree only if it matches the intended review state, otherwise materialize a separate snapshot without changing the user's checkout. Preserve the working tree and existing files. Provide the reference spec and other necessary requirements as readable files or in the dispatch prompt.

Check that every changed file and required input is accessible to reviewers. Include deletions in the diff and identify them in the scope. When a reviewer needs missing supporting context, supply it and resume that review; do not count an incomplete review as zero findings.

### Step 3: Dispatch subagents

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
- Head SHA or working-tree state: {state}
- Files changed: {paths}
- Diff file: {absolute path}
- Head source snapshot: {absolute path}
- Reference spec and requirements: {readable paths or supplied text; omit if none}

Use read, glob, and grep to examine the diff and every changed file in the supplied snapshot. Shell and Git are unavailable. Request missing inputs from the orchestrator; state any unexamined scope rather than reporting a clean review. For each finding, return one row in TOON tabular format:

findings[N]{id,axis,severity,location,observed,expected,impact,recommendation}:
  <id,axis,severity,code://path:line,observed,expected,impact,recommendation>

Use the code:// scheme for locations. Use stable slugs in id, never section numbers. For a complete review, return only the TOON block above — no preamble, no commentary, no markdown. If blocked, explicitly report the missing input and unexamined scope. Do not modify any files.
```

### Step 4: Await all responses

Wait for every dispatched subagent to complete. Collect their TOON output. Resolve missing inputs and resume incomplete reviews before proceeding; if an input cannot be provided, report the review as incomplete rather than generating a clean report.

### Step 5: Merge findings

1. Collect all finding rows from all subagents
2. Deduplicate by (axis, location, observed) — same axis, same location, same observed behaviour
3. On conflict: keep highest severity, list all reporting agents
4. Group by axis for presentation

### Step 6: Write consolidated document

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

For a working-tree review, set `headSha` to the checked-out SHA followed by ` (working tree)` so the report does not imply the commit alone was reviewed.

### Step 7: Generate report

Do NOT summarise or format the findings yourself. Instead, run the report script (vendored at `${FIXTURES_DIR}/code-review.report.sh` — same fixture mechanism as `adr.build.sh`):

```bash
bash ${FIXTURES_DIR}/code-review.report.sh .agents/forge/code-review/<run-id>/consolidated.toon > .agents/forge/code-review/<run-id>/report.md
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
