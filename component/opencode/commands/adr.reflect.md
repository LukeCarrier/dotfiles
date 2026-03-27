---
description: Capture learnings and improve the ADR process
agent: adrian
subtask: false
---

Use `/adr.reflect` once `/adr.implement` finishes so you can codify what happened and tighten the process for next time.

## Preparation

1. Current date:

   ```
   !date +"%Y-%m-%d"
   ```

2. Feature name:

   ```
   $1
   ```

3. Gather `spec.md`, `plan.md`, `tasks.md`, commit history, and any runbooks or incident notes.

## Process

1. **Review the cycle** — Compare the shipped implementation to each ADR artifact. Note mismatches, missing tests, or contradictions (e.g., pruning behavior vs. template/apply rules).
2. **Document evidence** — Capture real metrics, test outcomes, and rollout notes. Avoid vague statements.
3. **Record learnings** — Write a retrospective at `adrs/.meta/$currentDate-$featureName-retrospective.md` covering what worked, what failed, and concrete actions.
4. **Propose improvements** — Call out updates needed in `agent/adrian.md`, command templates, skills, or repository structure (such as extracting workflow-matrix logic into scripts for testing).
5. **Update statuses** — Set each ADR artifact `status` to `implemented` (or another accurate state) and refresh `adrs/.meta/index.md`.
6. **Request approvals** — Present any instruction or workflow changes to the user before editing agent docs.

## Output

- `adrs/$currentDate-$featureName/retro.md` summarizing the learnings and linking to the retrospective in `.meta`
- `adrs/.meta/$currentDate-$featureName-retrospective.md` using the standard template
- Recommendations for instruction or tooling updates with clear owners

Keep the tone plain and actionable. The goal is to prevent future ambiguity by teaching the next agent exactly what to repeat or avoid.
