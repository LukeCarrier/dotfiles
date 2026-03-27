---
description: Break an ADR plan into implementable tasks
agent: adrian
subtask: false
---

Translate the plan into work that can be scheduled immediately. Only run after `plan.md` is complete and aligned with the spec.

## Preparation

1. Current date:

   ```
   !date +"%Y-%m-%d"
   ```

2. Feature name:

   ```
   $1
   ```

3. Read `spec.md` and `plan.md`. Note section headings for cross-references.

## Process

1. Break the plan into tasks sized for 1–3 days of work. Combine steps only if they share the same code path and validation.
2. For each task, record:
   - Summary
   - Relevant spec/plan sections (use headings or anchors)
   - Acceptance criteria tied to observable behavior
   - Required tests (unit, integration, workflow script/BATS, etc.)
   - Dependencies and rollout/rollback notes
3. Highlight ownership or skill requirements when relevant (e.g., Terraform, workflow authoring).
4. Keep language direct and free of filler. State who does what and how success is measured.
5. If the plan has contradictions or missing information, stop and update the earlier documents instead of inventing new behavior.

## Output

Write `adrs/$currentDate-$featureName/tasks.md` including:

- An ordered list or table of tasks that covers every planned change
- Acceptance criteria and test expectations for each task
- Dependencies, sequencing, and any environment-specific handling
- Checkboxes or fields for implementers to mark progress

Ensure the YAML frontmatter is present and `status` reflects readiness for implementation. The final task list should make it obvious how to implement, test, and roll back the feature without referring back to conversations.
