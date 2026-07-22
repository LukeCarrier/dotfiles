# Converts ADR plan TOON to human-readable plan.md.
# Usage: toon decode plan.toon | jq -f plan.jq -r

. as $root |

"# \($root.title)",
"",
"## Approach",
"",
$root.approach,
"",
"## Architecture",
"",
$root.architecture,
"",
"## Technologies",
"",
"| Technology | Role |",
"|------------|------|",
($root.technologies[] | "| \(.name) | \(.role) |"),
"",
"## Components",
"",
($root.components[] |
  "### \(.name)",
  "",
  .purpose,
  "",
  (if .details then "\(.details)\n\n" else "" end)
),
(if $root.dataFlow then
  "## Data Flow\n\n\($root.dataFlow)\n\n"
else "" end),
(if $root.deployment then
  "## Deployment\n\n\($root.deployment)\n"
else "" end)
