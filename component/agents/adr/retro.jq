# Converts ADR retro TOON to human-readable retro.md.
# Usage: toon decode retro.toon | jq -f retro.jq -r

. as $root |

"# \($root.title)",
"",
"## What Went Well",
"",
($root.wentWell[] | "- \(.)"),
"",
"## What Didn't Go Well",
"",
($root.wentBadly[] | "- \(.)"),
"",
"## Process Improvements",
"",
($root.improvements[] | "- \(.)")
