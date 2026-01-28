---
description: Create a technical plan based on an ADR specification
agent: adrian
subtask: false
---

Create a technical plan based on the specification. Use this command after `/adr.specify` to:

- Declare architecture and stack
- Define constraints and standards
- Propose implementation approach
- Identify risks and mitigation strategies

## Arguments

Current date:

```
!date +"%Y-%m-%d"
```

Feature name:

```
$1
```

## Output

A technical plan that includes:

- Architecture overview
- Technology stack justification
- Component breakdown
- Data flow diagrams
- Testing strategy
- Deployment considerations

Persisted to**: `adrs/$currentDate-$featureName/plan.md`
