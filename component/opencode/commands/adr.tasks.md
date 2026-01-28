---
description: Break an ADR plan into implementable tasks
agent: adrian
subtask: false
---

Break the plan into implementable tasks. Use this command after `/adr.plan` to:

- Create small, reviewable units of work
- Define clear acceptance criteria for each task
- Identify dependencies between tasks
- Estimate complexity and effort

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

A task list where each task:
- Is independently implementable
- Has clear success criteria
- Includes test requirements
- References relevant specification sections

Persisted to: `adrs/$currentDate-$featureName/tasks.md`
