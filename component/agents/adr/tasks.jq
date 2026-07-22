# Converts ADR tasks TOON to human-readable tasks.md.
# Usage: toon decode tasks.toon | jq -f tasks.jq -r

def complexity_label($c):
  if $c == "low" then "🟢 Low"
  elif $c == "medium" then "🟡 Medium"
  elif $c == "high" then "🔴 High"
  else $c end;

. as $root |

"# \($root.title)",
"",
"## Tasks",
"",
($root.items[] |
  "### \(.id): \(.title)",
  "",
  (if .description then "\(.description)\n\n" else "" end),
  "| Field | Value |",
  "|-------|-------|",
  "| Success Criteria | \(.criteria) |",
  "| Complexity | \(complexity_label(.complexity)) |",
  "| Effort | \(.effort) |",
  (if .dependencies then "| Depends On | \(.dependencies) |" else "" end),
  (if .refs then "| References | \(.refs) |" else "" end),
  ""
)
