# Converts code-review findings JSON to markdown report.
# Usage: toon decode consolidated.toon | jq -f report.jq -r

def severity_label($s):
  if $s == "critical" then "CRITICAL"
  elif $s == "high" then "HIGH"
  elif $s == "medium" then "MEDIUM"
  elif $s == "low" then "LOW"
  else $s end;

. as $root |

"# Code Review Report",
"",
"**Run ID:** \($root.review.runId)",
"",
"**Scope:** \($root.review.scope.baseSha)..\($root.review.scope.headSha)",
"",
"**Files:**",
($root.review.scope.filesChanged[] | "- `\(.)`"),
"",
(if $root.review.scope.referenceIds then "**Reference:** \($root.review.scope.referenceIds | join(", "))" else empty end),
"",
"---",
"",
"## Summary",
"",
"| Agent | Role | Findings |",
"|-------|------|----------|",
($root.agents[] | "| \(.name) | \(.role) | \(.findingsCount) |"),
"",
"**Total:** \($root.findings | length) findings",
"",
"---",
"",
"## Findings",
"",
($root.findings[] |
  "### \(.id)",
  "",
  "| Field | Detail |",
  "|-------|--------|",
  "| Axis | \(.axis) |",
  "| Severity | \(severity_label(.severity)) |",
  "| Location | `\(.location)` |",
  "| Observed | \(.observed) |",
  "| Expected | \(.expected) |",
  "| Impact | \(.impact) |",
  "| Recommendation | \(.recommendation) |",
  (if .externalId then "| External | \(.externalId) |" else empty end),
  "",
  "---",
  ""
)
