---
description: Generate or refine an ADR specification
agent: adrian
subtask: false
---

Generate or refine the specification. Use this command when:

- Starting a new ADR.
- Requirements are unclear or incomplete.
- You need to validate understanding of the problem space.

## Arguments

Current date:

```
!date +"%Y-%m-%d"
```

Raw arguments:

```
$ARGUMENTS
```

Feature name is the first word. Feature description is everything else.

## Output

A detailed specification document that includes:

- Goals and user journeys
- Functional requirements
- Non-functional requirements
- Acceptance criteria
- Edge cases and error handling

Persisted to: `adrs/$currentDate-$featureName/spec.md`
