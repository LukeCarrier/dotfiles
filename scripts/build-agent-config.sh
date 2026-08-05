#!/usr/bin/env bash
# Build and test agent configuration without applying home-manager
set -euo pipefail

AGENT="${1:-}"
shift || true

# Parse optional flags
ACTION="run"
HOST="lukecarrier@luke-c0nstruct"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-only)
            ACTION="build"
            shift
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            # Everything else gets passed to the agent
            break
            ;;
    esac
done

if [[ -z "$AGENT" ]]; then
    cat <<EOF
Usage: $0 <agent> [--build-only] [--host <host>] [agent args...]

Agents: opencode, goose, claude-code, codex

Options:
  --build-only  Just build config and print store path (default: run agent)
  --host HOST   Build for specific host (default: lukecarrier@luke-c0nstruct)

Examples:
  $0 opencode --build-only
  $0 opencode .
  $0 goose --host lukecarrier@luke-f1xable
  $0 claude-code --mcp-config foo.json
EOF
    exit 1
fi

case "$AGENT" in
    opencode)
        CONFIG_PATH=".config/opencode"
        CONFIG_DIR=".config/opencode"
        BINARY="opencode"
        ENV_VARS=("XDG_CONFIG_HOME" "HOME")
        ;;
    goose)
        CONFIG_PATH=".config/goose"
        CONFIG_DIR=".config/goose"
        BINARY="goose"
        ENV_VARS=("XDG_CONFIG_HOME" "HOME")
        ;;
    claude-code)
        CONFIG_PATH=".claude"
        CONFIG_DIR=".claude"
        BINARY="claude"
        ENV_VARS=("HOME")
        ;;
    codex)
        CONFIG_PATH=".config/codex"
        CONFIG_DIR=".config/codex"
        BINARY="codex"
        ENV_VARS=("XDG_CONFIG_HOME" "HOME")
        ;;
    *)
        echo "Error: Unknown agent '$AGENT'"
        echo "Must be one of: opencode, goose, claude-code, codex"
        exit 1
        ;;
esac

echo "Building $AGENT configuration for $HOST..." >&2
CONFIG_STORE_PATH=$(nix build \
    --print-out-paths \
    --no-link \
    ".#homeConfigurations.\"$HOST\".config.home.file.\"$CONFIG_PATH\".source")

if [[ "$ACTION" == "build" ]]; then
    echo "$CONFIG_STORE_PATH"
    exit 0
fi

# For 'run' action, create a temporary HOME with configs
TEMP_HOME=$(mktemp -d)
trap "rm -rf '$TEMP_HOME'" EXIT

# Copy the config directory (can't symlink - agents need to write to it)
# Use rsync -rL to follow symlinks and copy actual files
mkdir -p "$TEMP_HOME/$CONFIG_DIR"
rsync -rL "$CONFIG_STORE_PATH/" "$TEMP_HOME/$CONFIG_DIR/"
chmod -R u+w "$TEMP_HOME/$CONFIG_DIR"

# Create data directories that agents need
mkdir -p "$TEMP_HOME/.local/share/$AGENT"
mkdir -p "$TEMP_HOME/.local/state/$AGENT"
mkdir -p "$TEMP_HOME/.cache/$AGENT"

echo "Launching $BINARY with test config from $CONFIG_STORE_PATH" >&2
echo "Temporary HOME: $TEMP_HOME" >&2
echo "" >&2

# Launch with new HOME, passing remaining args
exec env HOME="$TEMP_HOME" "$BINARY" "$@"
