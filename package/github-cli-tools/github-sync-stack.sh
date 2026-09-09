#!/usr/bin/env bash
set -euo pipefail

READY=false
for arg in "$@"; do
  case "$arg" in
    --ready) READY=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

declare -A BOOKMARK_MAP=()
while IFS=' ' read -r commit name; do
  [[ -z "$name" || "$name" == *"<Error"* ]] && continue
  [[ -z "${BOOKMARK_MAP[$commit]+_}" ]] && BOOKMARK_MAP["$commit"]="$name"
done < <(jj bookmark list --template 'self.normal_target().commit_id().short() ++ " " ++ name ++ "\n"' 2>/dev/null)

mapfile -t REVISIONS < <(
  jj log -r 'trunk()..@ & ancestors(@)' --no-graph --reversed \
    --template 'commit_id.short() ++ "\t" ++ description.first_line() ++ "\n"'
)

[[ ${#REVISIONS[@]} -eq 0 ]] && { echo "Nothing between trunk() and @." >&2; exit 0; }

declare -a COMMIT_IDS=() TITLES=() BOOKMARKS=()
for rev in "${REVISIONS[@]}"; do
  commit="${rev%%$'\t'*}"
  title="${rev#*$'\t'}"
  COMMIT_IDS+=("$commit")
  TITLES+=("$title")
  BOOKMARKS+=("${BOOKMARK_MAP[$commit]:-}")
done

REMOTE=$(jj git remote list | awk 'NR==1{print $1}')
[[ -z "$REMOTE" ]] && { echo "No git remote found." >&2; exit 1; }

TRUNK=$(jj log -r 'trunk()' --no-graph \
  --template 'local_bookmarks.map(|b| b.name()).join("\n") ++ "\n"' | head -1)
TRUNK="${TRUNK:-main}"

track_args=()
push_args=()
for b in "${BOOKMARKS[@]}"; do
  [[ -n "$b" ]] && track_args+=("${b}@${REMOTE}") && push_args+=(--bookmark "$b")
done
[[ ${#track_args[@]} -gt 0 ]] && jj bookmark track "${track_args[@]}"
[[ ${#push_args[@]} -gt 0 ]] && jj git push "${push_args[@]}" --remote "$REMOTE"

# Collect PR numbers for our bookmarks so we can find all affected stacks.
declare -A PR_NUMBER_FOR=()
declare -A PR_URL_FOR=()
declare -A PR_BASE_FOR=()
for b in "${BOOKMARKS[@]}"; do
  [[ -z "$b" ]] && continue
  row=$(gh pr list --head "$b" --state open --json number,url,baseRefName --jq 'first // ""')
  PR_NUMBER_FOR[$b]=$(jq -r '.number // ""' <<< "$row")
  PR_URL_FOR[$b]=$(jq -r '.url // ""' <<< "$row")
  PR_BASE_FOR[$b]=$(jq -r '.baseRefName // ""' <<< "$row")
done

# Fetch all stacks and unstack any containing our PR numbers.
all_stacks=$(gh api "repos/{owner}/{repo}/stacks")
our_numbers=$(printf '%s\n' "${PR_NUMBER_FOR[@]}" | grep -v '^$' | jq -Rn '[inputs | tonumber]')
mapfile -t stacks_to_remove < <(jq -r \
  --argjson nums "$our_numbers" \
  '[.[] | select(any(.pull_requests[].number; IN($nums[]))) | .number] | .[]' \
  <<< "$all_stacks")
for sn in "${stacks_to_remove[@]}"; do
  echo "  unstacking stack #$sn"
  gh api --method POST "repos/{owner}/{repo}/stacks/${sn}/unstack" --silent || true
done

declare -a PR_NUMBERS=() PR_URLS=()
n=${#COMMIT_IDS[@]}
for (( i=0; i<n; i++ )); do
  bookmark="${BOOKMARKS[$i]}"
  if [[ -z "$bookmark" ]]; then
    echo "  skip  ${COMMIT_IDS[$i]} — no bookmark"
    PR_NUMBERS+=("")
    PR_URLS+=("")
    continue
  fi

  existing_number="${PR_NUMBER_FOR[$bookmark]:-}"
  existing_url="${PR_URL_FOR[$bookmark]:-}"
  existing_base="${PR_BASE_FOR[$bookmark]:-}"

  base="$TRUNK"
  for (( j=i-1; j>=0; j-- )); do
    if [[ -n "${BOOKMARKS[$j]}" ]]; then base="${BOOKMARKS[$j]}"; break; fi
  done

  if [[ -n "$existing_url" ]]; then
    if [[ "$existing_base" != "$base" ]]; then
      echo "  update $existing_url (base: $existing_base → $base)"
      gh api --method PATCH "repos/{owner}/{repo}/pulls/$existing_number" -f base="$base" --silent
    else
      echo "  ok     $existing_url"
    fi
    $READY && gh pr ready "$existing_url"
    PR_NUMBERS+=("$existing_number")
    PR_URLS+=("$existing_url")
  else
    $READY && draft="" || draft="--draft"
    url=$(gh pr create --head "$bookmark" --base "$base" \
      --title "${TITLES[$i]}" --fill ${draft:+"$draft"})
    number="${url##*/}"
    echo "  created $url"
    PR_NUMBERS+=("$number")
    PR_URLS+=("$url")
  fi
done

stack_prs=()
for (( i=0; i<n; i++ )); do
  [[ -n "${PR_NUMBERS[$i]}" ]] && stack_prs+=("${PR_NUMBERS[$i]}")
done

if [[ ${#stack_prs[@]} -gt 1 ]]; then
  pr_json=$(printf '%s\n' "${stack_prs[@]}" | jq -Rn '[inputs | tonumber]')
  gh api --method POST "repos/{owner}/{repo}/stacks" --input - <<< "{\"pull_requests\": $pr_json}" --silent
  echo "  stack created: ${stack_prs[*]}"
fi

echo ""
echo "PR stack:"
for (( i=0; i<n; i++ )); do
  [[ -n "${PR_URLS[$i]}" ]] && printf "  %s  (%s)\n" "${PR_URLS[$i]}" "${BOOKMARKS[$i]}"
done
