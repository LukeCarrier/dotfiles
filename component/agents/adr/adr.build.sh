#!/usr/bin/env bash
# Validates and renders ADR .toon files to human-readable .md files.
# Usage: ./adr.build.sh <adr-directory>
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

  # Inline {{mermaid: <file>}} references as fenced code blocks.
  # Author writes {{mermaid: architecture.mmd}} in TOON free-text fields;
  # adr.build.sh replaces the entire line with the .mmd content wrapped in ```mermaid.
  if grep -q '{{mermaid: ' "$md_file" 2>/dev/null; then
    tmp_file=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ \{\{mermaid:\ ([^}]+)\}\} ]]; then
        mmd_file="$ADR_DIR/${BASH_REMATCH[1]}"
        printf '\n```mermaid\n' >> "$tmp_file"
        if [[ -f "$mmd_file" ]]; then
          cat "$mmd_file" >> "$tmp_file"
        else
          echo "<!-- mermaid: file not found: ${BASH_REMATCH[1]} -->" >> "$tmp_file"
        fi
        printf '\n```\n' >> "$tmp_file"
      else
        printf '%s\n' "$line" >> "$tmp_file"
      fi
    done < "$md_file"
    mv "$tmp_file" "$md_file"
  fi

  echo "✓ $md_file"
  rendered=$((rendered + 1))
done

if [[ $rendered -eq 0 ]]; then
  echo "No .toon files found in $ADR_DIR" >&2
  exit 1
fi
