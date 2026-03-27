---
description: Implement an ADR following defined tasks
subtask: false
---

Use this command once `spec.md`, `plan.md`, and `tasks.md` are accepted. Implementation must follow the documented intent exactly.

## Before writing code

1. Confirm the ADR artifacts exist under `adrs/<date>-<feature>/` and contain current frontmatter.
2. Re-read the spec and plan. Resolve any contradictions (e.g., pruning without running template/apply). If the documents disagree, stop and send the issue back to `/adr.plan` or `/adr.specify`.
3. Review the task list. Ensure each task has clear acceptance criteria and test requirements. Ask for clarification if anything cannot be tested.
4. Identify tooling requirements (e.g., scripts extracted for workflow-matrix generation, BATS harnesses). Set them up before touching production infrastructure.

## During implementation

1. Work task-by-task, in order. Update `tasks.md` as you complete items.
2. Mirror the documented behavior. If you must deviate, document the change in `plan.md`/`tasks.md` and pause for approval.
3. Build the promised tests. For workflow logic, test the script that produces matrices/pruning decisions rather than the workflow file itself.
4. Keep region-specific logic honest: if pruning runs in a region, template/apply must run there too. If a region is skipped, ensure all related destructive steps are also skipped.

## After implementation

1. Validate that every acceptance criterion in `spec.md` and `tasks.md` is covered by code and tests.
2. Update ADR artifacts with any learnings (status, timestamps, deviations).
3. Prepare rollout notes, monitoring hooks, and rollback steps noted in the plan.
4. Pause for operator review. Present the diff, test results, and any outstanding questions so the operator can validate behavior and perform required source control operations before you proceed further.
5. Hand off to `/adr.reflect` to capture the cycle.

## Input

Current date:

```
!date +"%Y-%m-%d"
```

Feature name:

```
$1
```
