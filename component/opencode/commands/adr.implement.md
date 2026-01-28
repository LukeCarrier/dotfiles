---
description: Implement an ADR following defined tasks
subtask: false
---

## Before writing code

1. Ensure the specification is complete and unambiguous.
2. Verify that the implementation aligns with the technical plan.
3. Confirm `spec.md`, `plan.md`, and `tasks.md` exist in the feature directory. Ensure the user is satisfied that they pass their quality gates.

### During implementation

1. Focus on one task at a time. Complete it fully before moving to the next.
2. Regularly check that the implementation matches the specification.
3. Write tests that validate the specification requirements, not just the code.

### After implementation

1. Update the specification based on implementation learnings.
2. Ensure the code documents how it fulfills the specification.
3. Validate that the implementation meets all acceptance criteria.

## Input

Current date:

```
!date +"%Y-%m-%d"
```

Feature name:

```
$1
```
