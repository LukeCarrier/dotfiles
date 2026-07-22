#!/usr/bin/env bash
# Validates and renders ADR .toon files to human-readable .md files.
# Usage: ./build.sh <adr-directory>
# Requires: toon (from toon-cli), jq, check-jsonschema

set -euo pipefail

ADR_DIR="${1:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rendered=0

for artifact in spec plan tasks retro; do
  toon_file="$ADR_DIR/$artifact.toon"
  md_file="$ADR_DIR/$artifact.md"
  jq_file="$SCRIPT_DIR/$artifact.jq"
  schema_file="$SCRIPT_DIR/$artifact.schema.json"

  if [[ ! -f "$toon_file" ]]; then
    continue
  fi

  if [[ ! -f "$jq_file" ]]; then
    echo "Warning: no jq template for $artifact (expected $jq_file)" >&2
    continue
  fi

  tmp_json=$(mktemp)
  trap 'rm -f "$tmp_json"' EXIT

  toon --decode "$toon_file" > "$tmp_json"

  if [[ -f "$schema_file" ]]; then
    check-jsonschema --schemafile "$schema_file" "$tmp_json" >&2
  fi

  jq -f "$jq_file" -r "$tmp_json" > "$md_file"
  echo "✓ $md_file"
  rendered=$((rendered + 1))
done

if [[ $rendered -eq 0 ]]; then
  echo "No .toon files found in $ADR_DIR" >&2
  exit 1
fi
