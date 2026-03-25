#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Clone accessible repositories from a GitHub organization.

Usage:
  github-clone-many.sh --org <org> [options]

Required:
  --org <org>                 GitHub organization name

Options:
  --dest <dir>                Destination directory (default: current directory)
  --protocol <ssh|https>      Clone protocol (default: ssh)
  --search <query>            Extra search qualifiers/terms. Search always enforces
                              org:<org> and archived:false
  --limit <n>                 Maximum repos to enumerate (default: 1000)
  --clone-with <git|jj>       Clone tool to use (default: git)
                              Note: jj mode performs a single-branch git clone,
                              then initializes a colocated jj repo
                              Existing repos are fetched instead of skipped
  --fail-fast                 Exit immediately on first clone error
  --dry-run                   Print what would be cloned
  -h, --help                  Show help

Examples:
  github-clone-many.sh --org my-org --dest ~/src/my-org
  github-clone-many.sh --org my-org --search 'topic:terraform language:go'
  github-clone-many.sh --org my-org --clone-with jj
EOF
}

ORG=""
DEST="."
PROTOCOL="ssh"
SEARCH=""
LIMIT=1000
CLONE_WITH="git"
FAIL_FAST=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    --protocol) PROTOCOL="${2:-}"; shift 2 ;;
    --search) SEARCH="${2:-}"; shift 2 ;;
    --limit) LIMIT="${2:-}"; shift 2 ;;
    --clone-with) CLONE_WITH="${2:-}"; shift 2 ;;
    --fail-fast) FAIL_FAST=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$ORG" ]]; then
  echo "Error: --org is required." >&2
  usage
  exit 1
fi

if [[ "$PROTOCOL" != "ssh" && "$PROTOCOL" != "https" ]]; then
  echo "Error: --protocol must be 'ssh' or 'https'." >&2
  exit 1
fi

if [[ "$CLONE_WITH" != "git" && "$CLONE_WITH" != "jj" ]]; then
  echo "Error: --clone-with must be 'git' or 'jj'." >&2
  exit 1
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -le 0 ]]; then
  echo "Error: --limit must be a positive integer." >&2
  exit 1
fi

command -v gh >/dev/null 2>&1 || {
  echo "Error: gh CLI is required." >&2
  exit 1
}

command -v git >/dev/null 2>&1 || {
  echo "Error: git is required." >&2
  exit 1
}

if [[ "$CLONE_WITH" == "jj" ]]; then
  command -v jj >/dev/null 2>&1 || {
    echo "Error: jj is required when --clone-with jj." >&2
    exit 1
  }
fi

gh auth status >/dev/null 2>&1 || {
  echo "Error: gh is not authenticated. Run: gh auth login" >&2
  exit 1
}

mkdir -p "$DEST"

list_repos() {
  if [[ -n "$SEARCH" ]]; then
    local q="org:${ORG} archived:false ${SEARCH}"
    gh search repos "$q" \
      --limit "$LIMIT" \
      --json nameWithOwner,isArchived \
      --jq '.[] | select(.isArchived | not) | .nameWithOwner'
  else
    gh repo list "$ORG" \
      --limit "$LIMIT" \
      --json nameWithOwner,isArchived \
      --jq '.[] | select(.isArchived | not) | .nameWithOwner'
  fi
}

clone_repo() {
  local full_name="$1"
  local target_dir="$2"
  local default_branch="$3"
  local repo_name="$4"
  local clone_url

  if [[ "$PROTOCOL" == "ssh" ]]; then
    clone_url="git@github.com:${full_name}.git"
  else
    clone_url="https://github.com/${full_name}.git"
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would clone (${CLONE_WITH}): ${full_name} (default branch: ${default_branch})"
    return 0
  fi

  if [[ "$CLONE_WITH" == "git" ]]; then
    git -C "$DEST" clone --single-branch --branch "$default_branch" "$clone_url" "$repo_name" || return $?
  else
    git -C "$DEST" clone --single-branch --branch "$default_branch" "$clone_url" "$repo_name" || return $?
    jj git init --colocate "$target_dir" || return $?
  fi

  return 0
}

fetch_existing_repo() {
  local full_name="$1"
  local target_dir="$2"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would fetch (${CLONE_WITH}): ${full_name}"
    return 0
  fi

  if [[ "$CLONE_WITH" == "git" ]]; then
    git -C "$target_dir" fetch --prune || return $?
  else
    jj -R "$target_dir" git fetch || return $?
  fi

  return 0
}

get_default_branch() {
  local full_name="$1"
  gh repo view "$full_name" --json defaultBranchRef --jq '.defaultBranchRef.name'
}

cloned=0
fetched=0
skipped=0
failed=0

while IFS= read -r full_name; do
  [[ -z "$full_name" ]] && continue

  repo_name="${full_name#*/}"
  target="${DEST}/${repo_name}"
  default_branch=""

  if [[ -d "$target" ]]; then
    if [[ -d "$target/.git" || -d "$target/.jj" ]]; then
      if [[ $DRY_RUN -eq 0 ]]; then
        echo "Fetching (${CLONE_WITH}): ${full_name}"
      fi

      if fetch_existing_repo "$full_name" "$target"; then
        fetched=$((fetched + 1))
      else
        failed=$((failed + 1))
        echo "Failed to fetch existing repo: ${full_name}" >&2

        if [[ $FAIL_FAST -eq 1 ]]; then
          echo "Stopping due to --fail-fast." >&2
          exit 1
        fi
      fi

      continue
    fi

    echo "Skipping (exists but is not a repo): ${full_name}" >&2
    skipped=$((skipped + 1))
    continue
  fi

  if ! default_branch="$(get_default_branch "$full_name")" || [[ -z "$default_branch" ]]; then
    failed=$((failed + 1))
    echo "Failed to resolve default branch: ${full_name}" >&2

    if [[ $FAIL_FAST -eq 1 ]]; then
      echo "Stopping due to --fail-fast." >&2
      exit 1
    fi

    continue
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    echo "Cloning (${CLONE_WITH}): ${full_name} (default branch: ${default_branch})"
  fi

  if clone_repo "$full_name" "$target" "$default_branch" "$repo_name"; then
    cloned=$((cloned + 1))
    continue
  fi

  failed=$((failed + 1))
  echo "Failed to clone: ${full_name}" >&2

  if [[ $FAIL_FAST -eq 1 ]]; then
    echo "Stopping due to --fail-fast." >&2
    exit 1
  fi
done < <(list_repos)

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run complete. ${cloned} repos would be cloned, ${fetched} fetched, ${skipped} skipped."
else
  echo "Done. ${cloned} repos cloned, ${fetched} fetched, ${skipped} skipped, ${failed} failed."

  if [[ $failed -gt 0 ]]; then
    exit 1
  fi
fi
