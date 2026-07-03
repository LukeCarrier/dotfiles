{ pkgs }:
# Shell snippet defining mergeJsonConfig <base> <target>: merge managed JSON
# (base, a store path) over a mutable target file, preserving keys the owning
# tool writes itself (auths, currentContext, ...). Replaces a store symlink with
# a real file so the tool can rewrite it.
''
  mergeJsonConfig() {
    local base="$1"
    local target="$2"
    $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
      $DRY_RUN_CMD unlink "$target"
    fi
    if [ -f "$target" ]; then
      local tmp
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq --slurpfile base "$base" '. * $base[0]' "$target" > "$tmp"
      chmod 644 "$tmp"
      $DRY_RUN_CMD mv -f "$tmp" "$target"
    else
      $DRY_RUN_CMD install -m 644 "$base" "$target"
    fi
  }
''
