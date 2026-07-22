#!/usr/bin/env bash
# Converts a code-review consolidated.toon file to a human-readable markdown report.
# Usage: ./report.sh [input.toon] > report.md
#
# Requires: toon (from toon-cli), jq
# Both are provided by the Nix derivation; outside Nix, install manually.

set -euo pipefail

INPUT="${1:-/dev/stdin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

toon --decode "$INPUT" | jq -f "$SCRIPT_DIR/report.jq" -r
