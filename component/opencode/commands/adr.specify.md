---
description: Generate or refine an ADR specification
agent: adrian
subtask: false
---

Create a specification that another engineer could implement without guessing. Run this command when starting a feature or when requirements drift from earlier ADRs.

## Preparation

1. Capture the current date for the ADR folder name when creating a new record (use the original folder date when revisiting an ADR):

   ```
   !date +"%Y-%m-%d"
   ```

2. Arguments:

   ```
   $ARGUMENTS
   ```

   - The first word is the feature slug.
   - Everything after the first word is the short description.

## Process

1. Read any existing ADRs for the same feature. List directories with the same slug in reverse chronological order so you inspect the most recent first. If more than one ADR might apply, use the question tool (when available) to ask the user which record to edit before proceeding. Align terminology with the chosen ADR; if disagreements exist, document them and resolve before proceeding.
2. Interview the user (or restate requirements) until you can list measurable success criteria.
3. Write in plain English. Explain the value, actors, and user journeys first.
4. Enumerate functional and non-functional requirements. Each requirement must have acceptance criteria and references to metrics or observable states.
5. Describe edge cases, failure handling, and regional nuances. Call out rules that differ per environment.
6. Confirm that every requirement could be tested. If not, the requirement needs more detail.

## Output

Produce `adrs/$currentDate-$featureName/spec.md` containing:

- Problem statement and business context
- User journeys / flows
- Functional requirements with acceptance criteria
- Non-functional requirements (latency, compliance, regions, etc.)
- Edge cases, failure handling, and rollback expectations
- Traceability back to any earlier specifications or contracts

Set the YAML frontmatter fields (`status`, `created`, `updated`, `author`, `decision`). Update `status` when the spec becomes review-ready.
