# Converts a cartography map TOON to human-readable map.md.
# Usage: toon decode map.toon | jq -f map.jq -r

def blocker_ids:
  ((.blockers // "")
   | split(",")
   | map(gsub("^[[:space:]]+|[[:space:]]+$"; ""))
   | map(select(length > 0)));

def state_of($tickets; $id):
  ([$tickets[] | select(.id == $id) | .state][0]) // "missing";

def is_blocked($tickets):
  blocker_ids as $ids
  | any($ids[]; state_of($tickets; .) != "answered");

. as $root
| ($root.tickets // []) as $tickets
| ([$tickets[] | select(.state == "answered")] | length) as $answered
| ([$tickets[] | select(.state == "open")] | length) as $open
| ([$tickets[] | select(.state == "probing")] | length) as $probing
| ([$tickets[] | select(.state == "abandoned")] | length) as $abandoned
| ([$tickets[]
    | select((.state == "open" or .state == "probing") and ((is_blocked($tickets)) | not))
    | .id]) as $frontier
| ([$tickets[]
    | select((.state == "open" or .state == "probing") and is_blocked($tickets))
    | .id]) as $blocked
| (
    "# Cartography map",
    "",
    "**Destination:** \($root.destination)",
    "",
    "Created: \($root.created)",
    "",

    "## Summary",
    "",
    "| Metric | Value |",
    "|--------|-------|",
    "| Tickets | \($tickets | length) |",
    "| Answered | \($answered) |",
    "| Open | \($open) |",
    "| Probing | \($probing) |",
    "| Abandoned | \($abandoned) |",
    "| Blocked | \($blocked | length) |",
    "| Frontier | \(if ($frontier | length) == 0 then "empty" else ($frontier | join(", ")) end) |",
    "",

    "## Tickets",
    "",

    ($tickets[]
     | "### \(.id): \(.question)",
       "",
       "| Field | Value |",
       "|-------|-------|",
       "| State | \(.state)\(
         if ((.state == "open" or .state == "probing") and is_blocked($tickets))
         then " (blocked by \(blocker_ids | join(", ")))"
         else ""
         end) |",
       (if (.blockers // "") != "" then "| Depends on | \(.blockers) |" else empty end),
       (if (.answer // "") != "" then "| Answer | \(.answer) |" else empty end),
       (if (.evidence // "") == "" then empty
        elif (.evidence | startswith("evidence/")) then "| Evidence | [\(.evidence)](\(.evidence)) |"
        else "| Evidence | \(.evidence) |"
        end),
       "")
  )
