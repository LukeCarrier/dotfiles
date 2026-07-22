#!/usr/bin/env bash
# Maintains adrs/README.md with all ADRs grouped by status.
# Reads from spec.toon files. Requires: toon (from toon-cli), jq.

set -euo pipefail

REPO_ROOT="$(echo "$PWD")"
ADRS_DIR="${ADRS_DIR:-$REPO_ROOT/adrs}"

if [[ ! -d "$ADRS_DIR" ]]; then
  echo "Error: adrs directory not found at $ADRS_DIR" >&2
  exit 1
fi

STATUSES=("implemented" "accepted" "draft" "rejected" "superseded")

read_spec_field() {
  local spec_file="$1"
  local field="$2"
  toon --decode "$spec_file" 2>/dev/null | jq -r ".${field} // empty" 2>/dev/null || true
}

is_valid_status() {
  local status="$1"
  for valid in "${STATUSES[@]}"; do
    [[ "$status" == "$valid" ]] && return 0
  done
  return 1
}

cat > "$ADRS_DIR/README.md" <<'EOF'
# Architecture Decision Records

This directory contains ADRs organized by status. ADRs follow a structured workflow:

1. `/adr.specify` - Define goals and requirements
2. `/adr.plan` - Architect the solution
3. `/adr.tasks` - Break down into implementable tasks
4. `/adr.implement` - Execute the plan
5. `/adr.reflect` - Capture learnings

EOF

declare -A adr_by_status

while IFS= read -r adr_dir; do
  dir_name="$(basename "$adr_dir")"

  spec_file="$adr_dir/spec.toon"
  created=""
  title=""

  if [[ -f "$spec_file" ]]; then
    status=$(read_spec_field "$spec_file" "status" || echo "draft")
    created=$(read_spec_field "$spec_file" "created" || echo "")
    title=$(read_spec_field "$spec_file" "title" || echo "")
  fi

  if [[ -z "$status" ]] || ! is_valid_status "$status"; then
    status="unknown"
  fi

  if [[ -z "$created" ]] && [[ "$dir_name" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    created="${BASH_REMATCH[1]}"
  fi

  adr_by_status["$status"]+="${created}|${dir_name}|${title}"$'\n'
done < <(find "$ADRS_DIR" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*' | sort -r)

for status in "${STATUSES[@]}"; do
  if [[ -n "${adr_by_status[$status]:-}" ]]; then
    heading="$(tr '[:lower:]' '[:upper:]' <<< "${status:0:1}")${status:1}"
    echo "## $heading" >> "$ADRS_DIR/README.md"
    echo "" >> "$ADRS_DIR/README.md"

    while IFS='|' read -r date dir_name adr_title; do
      [[ -z "$dir_name" ]] && continue

      if [[ -n "$adr_title" ]]; then
        display_title="$adr_title"
      else
        feature_name="${dir_name#*-*-*-}"
        display_title="$(tr '-' ' ' <<< "$feature_name" | sed 's/\b\(.\)/\u\1/g')"
      fi

      echo "- [\`$dir_name\`](./$dir_name/) - $display_title" >> "$ADRS_DIR/README.md"
    done < <(echo "${adr_by_status[$status]}" | grep -v '^$' | sort -r)

    echo "" >> "$ADRS_DIR/README.md"
  fi
done

if [[ -n "${adr_by_status[unknown]:-}" ]]; then
  echo "## Unknown Status" >> "$ADRS_DIR/README.md"
  echo "" >> "$ADRS_DIR/README.md"

  while IFS='|' read -r date dir_name adr_title; do
    [[ -z "$dir_name" ]] && continue

    if [[ -n "$adr_title" ]]; then
      display_title="$adr_title"
    else
      feature_name="${dir_name#*-*-*-}"
      display_title="$(tr '-' ' ' <<< "$feature_name" | sed 's/\b\(.\)/\u\1/g')"
    fi

    echo "- [\`$dir_name\`](./$dir_name/) - $display_title" >> "$ADRS_DIR/README.md"
  done < <(echo "${adr_by_status[unknown]}" | grep -v '^$' | sort -r)

  echo "" >> "$ADRS_DIR/README.md"
fi

echo "✓ Updated $ADRS_DIR/README.md"
