---
description: Capture learnings and improve the ADR process
agent: adrian
subtask: false
---

Reflect on a completed ADR cycle to capture learnings and improve future iterations. Use this command after `/adr.implement` completes to:

- Review what worked well and what caused friction
- Identify patterns and recurring issues
- Propose updates to agent instructions, skills, or workflows
- Synthesize learnings across multiple ADRs

## Arguments

Current date:

```
!date +"%Y-%m-%d"
```

Feature name:

```
$1
```

## Process

1. **Review the cycle** - Examine spec.md, plan.md, tasks.md, and implementation
2. **Identify learnings** - What was effective? What caused delays or confusion?
3. **Capture insights** - Document in `adrs/.meta/YYYY-MM-DD-retrospective.md`
4. **Propose improvements** - Updates to adrian.md, new skills, workflow changes
5. **Update status** - Set ADR status to `implemented` in frontmatter
6. **Update index** - Refresh `adrs/.meta/index.md` with current status

## Output

A retrospective document that includes:

- What worked well
- What didn't work
- Proposed improvements to the ADR process
- Patterns observed across multiple cycles
- Proposed updates to agent instructions (requires user approval)

Persisted to: `adrs/$currentDate-$featureName/retro.md`

Additionally, read and update `AGENTS.md` with any significant changes implemented by this ADR.
