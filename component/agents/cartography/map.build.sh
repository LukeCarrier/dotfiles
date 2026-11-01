#!/usr/bin/env bash
# Validates a cartography map.toon and renders map.md beside it.
# Usage: ./map.build.sh <map-directory>
# Requires: toon (from toon-cli), jq, check-jsonschema

set -euo pipefail

MAP_DIR="${1:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

toon_file="$MAP_DIR/map.toon"
md_file="$MAP_DIR/map.md"
jq_file="$SCRIPT_DIR/map.jq"
schema_file="$SCRIPT_DIR/map.schema.json"

if [[ ! -f "$toon_file" ]]; then
  echo "No map.toon found in $MAP_DIR" >&2
  exit 1
fi

if [[ ! -f "$jq_file" ]]; then
  echo "Warning: no jq template for map (expected $jq_file)" >&2
  exit 1
fi

tmp_json=$(mktemp)
trap 'rm -f "$tmp_json"' EXIT

toon --decode "$toon_file" > "$tmp_json"

check-jsonschema --schemafile "$schema_file" "$tmp_json" >&2

# Every blocker must name a ticket that exists in the same map.
if ! jq -e '
  (.tickets // []) as $t
  | all($t[];
      ((.blockers // "")
       | split(",")
       | map(gsub("^[[:space:]]+|[[:space:]]+$"; ""))
       | map(select(length > 0))
       | all(. as $b | $t | any(.id == $b))))
' "$tmp_json" >/dev/null; then
  echo "Error: map.toon has a blocker that does not name a ticket in this map" >&2
  exit 1
fi

jq -f "$jq_file" -r "$tmp_json" > "$md_file"

echo "✓ $md_file"
