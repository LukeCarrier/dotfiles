# Converts ADR spec TOON to human-readable spec.md.
# Usage: toon decode spec.toon | jq -f spec.jq -r

. as $root |

"# \($root.title)",
"",
"**Status:** \($root.status)  **Created:** \($root.created)  **Author:** \($root.author)",
"",
(if $root.context then "\($root.context)\n\n" else "" end),
"## Problem",
"",
$root.problem,
"",
"## Goals",
"",
($root.goals[] | "- \(.)"),
"",
(if ($root.nonGoals | length) > 0 then
  "## Non-goals\n\n" + ($root.nonGoals[] | "- \(.)") + "\n\n"
else "" end),
"## Functional Requirements",
"",
($root.requirements[] |
  "### \(.id): \(.title)",
  "",
  .description,
  "",
  "**Slug:** `\(.slug)`",
  ""
),
"## Non-functional Requirements",
"",
($root.nonFunctional[] |
  "### \(.id): \(.title)",
  "",
  .description,
  "",
  "**Slug:** `\(.slug)`",
  ""
),
"## Acceptance Criteria",
"",
($root.acceptance[] |
  "### \(.id): \(.title)",
  "",
  .description,
  "",
  "**Slug:** `\(.slug)`",
  ""
),
(if ($root.edgeCases | length) > 0 then
  "## Edge Cases\n\n" + ($root.edgeCases[] |
    "### \(.id): \(.title)\n\n\(.description)\n\n**Slug:** `\(.slug)`\n"
  )
else "" end)
