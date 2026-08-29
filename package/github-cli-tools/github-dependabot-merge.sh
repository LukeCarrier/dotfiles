set -euo pipefail

# Drain open Dependabot PRs through the merge queue.
#
# - PRs whose file sets overlap form a chain (e.g. everything touching
#   Cargo.lock, everything touching docs/yarn.lock); chains are drained one
#   member at a time, oldest first, so the queue never holds conflicting
#   entries.
# - Independent chains run concurrently (one process per chain). Once every
#   chain has drained, the open-PR pool is re-scanned (file sets shift as PRs
#   land) and further rounds run until no eligible PR remains.
# - A branch carrying human commits is never touched: warn and skip.
 # - A dirty (conflict), blocked (checks failed), or behind (stale) branch is
 #   regenerated first:
 #       only dependabot[bot] commits  -> "@dependabot rebase"
 #       any other bot commit          -> "@dependabot recreate"
 # - One regeneration attempt per PR; afterwards the PR is skipped and reported.
 # - Mergeability is determined via the REST mergeable_state field; no
 #   check-run inspection is required.
#
# Usage: drain-dependabot-prs.sh [--dry-run] [--include N]... [--poll-secs S]
#                                 [--merge-strategy squash|rebase|merge]
#
# --merge-strategy is required when the repository has no merge queue configured.
# When a merge queue is present it is detected automatically and PRs are enqueued.

REPO="${GITHUB_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
API_BASE="repos/${REPO}"
POLL_SECS=60
FAST_POLL_SECS=3
MERGE_TIMEOUT_SECS=3600
QUEUE_TIMEOUT_SECS=5400
REGEN_GRACE_SECS=1200
REGEN_MAX=1
DRY_RUN=0
INCLUDE=()
MERGE_STRATEGY=""  # squash | rebase | merge; required when no merge queue
MERGE_QUEUE=0      # set by probe_merge_queue
STATE_DIR=""       # set in main(); persists regen counts across rounds

declare -A CHAINS=()     # chain-id -> ordered PR numbers, oldest first
declare -A FILE_CHAIN=() # filename -> chain-id

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

api() { gh api "${API_BASE}/$1" "${@:2}"; }

# Sets MERGE_QUEUE=1 if the repository has a merge queue configured.
probe_merge_queue() {
	local owner repo result
	owner="${REPO%%/*}"
	repo="${REPO##*/}"
	result=$(gh api graphql -f query="
		query { repository(owner: \"$owner\", name: \"$repo\") {
			mergeQueue { id }
		} }" --jq '.data.repository.mergeQueue // ""' 2>/dev/null || true)
	if [[ -n "$result" ]]; then
		MERGE_QUEUE=1
		log "merge queue detected for $REPO"
	else
		MERGE_QUEUE=0
		log "no merge queue detected for $REPO; will use direct merge (--$MERGE_STRATEGY)"
	fi
}

# Fetch PR fields via REST.
#   .number .title .state (OPEN|CLOSED|MERGED)
#   .mergedAt        ISO timestamp or null
#   .headRefOid      head SHA
#   .mergeableState  clean | dirty | blocked | behind | unstable | draft | unknown
#   .baseRef         base branch name (e.g. main)
#   .baseSha         base branch tip SHA at PR creation time
pr_json() {
	local num=$1
	shift
	api "pulls/$num" --jq '
		{
			number:         .number,
			title:          .title,
			state:          (if .merged_at then "MERGED" elif .state == "closed" then "CLOSED" else "OPEN" end),
			mergedAt:       .merged_at,
			headRefOid:     .head.sha,
			mergeableState: .mergeable_state,
			baseRef:        .base.ref,
			baseSha:        .base.sha
		}' "$@"
}

pr_field() { pr_json "$1" | jq -r ".$2"; }

pr_files() { api "pulls/$1/files" --paginate --jq '.[].filename'; }

# True if PR $1's base is already the tip of its target ref (no rebase would change file content).
pr_base_is_tip() {
	local num=$1 pj base_ref base_sha tip_sha
	pj=$(pr_json "$num" 2>/dev/null) || return 1
	base_ref=$(jq -r .baseRef <<<"$pj")
	base_sha=$(jq -r .baseSha <<<"$pj")
	[[ -n "$base_ref" && "$base_ref" != "null" && -n "$base_sha" && "$base_sha" != "null" ]] || return 1
	tip_sha=$(gh api "repos/${REPO}/git/refs/heads/${base_ref}" --jq .object.sha 2>/dev/null) || return 1
	[[ -n "$tip_sha" && "$tip_sha" != "null" && "$base_sha" == "$tip_sha" ]]
}

# dependabot | other-bot | human:<who>
branch_class() {
	local num=$1 other_bot=0 seen=0 cauthor
	while IFS=$'\t' read -r cauthor _; do
		[[ -z "$cauthor" ]] && continue
		seen=$((seen + 1))
		if [[ "$cauthor" != *\[bot\] ]]; then
			echo "human:${cauthor:-unknown}"
			return
		fi
		if [[ "$cauthor" != "dependabot[bot]" ]]; then
			other_bot=1
		fi
	done < <(api "pulls/$num/commits" --paginate --jq \
		'.[] | [(.author.login // .commit.author.name // "<unknown>"), .sha] | @tsv')
	((seen)) || { echo "human:<unparsable>"; return; }
	((other_bot)) && { echo other-bot; return; }
	echo dependabot
}

record_merged() { log "PR #$1: merged"; }

skip_pr() { log "PR #$1: SKIP ($2)"; }

# Approve any workflow runs waiting for approval on $1 (PR number).
# Must be called after any transition that touches file content (rebase/
# recreate, merge of predecessor, etc.) — not just before recreate — because
# each new head SHA creates fresh runs in `waiting`/`action_required`.
approve_pending_workflows() {
	local num=$1 branch runs run_id approved=0
	branch=$(gh pr view "$num" --repo "$REPO" --json headRefName -q .headRefName 2>/dev/null) || return 0
	if [[ -z "$branch" ]]; then return 0; fi
	# `status=waiting` is the steady state, `action_required` is the initial state on some GHES versions
	for status in waiting action_required; do
		runs=$(gh api "repos/${REPO}/actions/runs?branch=${branch}&status=${status}&per_page=100" \
			--jq '.workflow_runs[] | select(.event == "pull_request" or .event == "pull_request_target") | .id' 2>/dev/null) || continue
		for run_id in $runs; do
			[[ -z "$run_id" || "$run_id" == "null" ]] && continue
			log "PR #$num: approving workflow run $run_id (status=$status, branch=$branch)"
			if ((DRY_RUN)); then
				approved=1
				continue
			fi
			if gh api -X POST "repos/${REPO}/actions/runs/${run_id}/approve" >/dev/null 2>&1; then
				approved=1
			else
				log "PR #$num: failed to approve run $run_id (may already be approved or lack permission)"
			fi
		done
	done
	if ((approved)); then
		log "PR #$num: approved pending workflows; re-polling for checks"
		# brief pause to let GH flip mergeable_state from blocked -> unstable/clean
		sleep "$FAST_POLL_SECS"
	fi
	return 0
}

comment_regen() {
	local num=$1 cmd=$2
	# No-op if base is already tip of the target ref — rebase/recreate would
	# not touch file content and would just spin (the "retarded spinning" case
	# where blocked is due to checks/workflows, not stale base).
	if pr_base_is_tip "$num"; then
		log "PR #$num: base already at tip of $(pr_field "$num" baseRef 2>/dev/null || echo "base"); skipping @dependabot $cmd (would be no-op)"
		return 2
	fi
	if ((DRY_RUN)); then
		log "PR #$num: DRY-RUN would comment '@dependabot $cmd'"
		return 1 # nothing will change; caller reports plan and stops
	fi
	log "PR #$num: commenting @dependabot $cmd"
	gh pr comment "$num" --repo "$REPO" --body "@dependabot $cmd" >/dev/null
}

# True when the head changed away from $2 within the grace period.
regen_responded() {
	local num=$1 old=$2 waited=0 head
	while ((waited < REGEN_GRACE_SECS)); do
		sleep "$POLL_SECS"
		waited=$((waited + POLL_SECS))
		if ! head=$(pr_field "$num" headRefOid); then
			log "PR #$num: regen poll at ${waited}s/${REGEN_GRACE_SECS}s: query failed; retrying"
			continue
		fi
		if [[ -n "$head" && "$head" != "$old" ]]; then
			log "PR #$num: dependabot regenerated after ${waited}s"
			return 0
		fi
		log "PR #$num: regen poll at ${waited}s/${REGEN_GRACE_SECS}s: head still $old"
	done
	log "PR #$num: dependabot did not respond within ${REGEN_GRACE_SECS}s"
	return 1
}

enqueue() {
	local num=$1
	if ((DRY_RUN)); then
		((MERGE_QUEUE)) && log "PR #$num: DRY-RUN would enqueue into merge queue" \
		                 || log "PR #$num: DRY-RUN would merge directly (--${MERGE_STRATEGY})"
		return
	fi
	if ((MERGE_QUEUE)); then
		log "PR #$num: gh pr merge --rebase (merge queue)"
		gh pr merge "$num" --repo "$REPO" --rebase >/dev/null
	else
		log "PR #$num: gh pr merge --${MERGE_STRATEGY}"
		gh pr merge "$num" --repo "$REPO" "--${MERGE_STRATEGY}" >/dev/null
		record_merged "$num"
	fi
}

# Returns 0 merged, 1 ejected (conflict/failure), 2 timed out.
wait_queue() {
	local num=$1 waited=0 pj state ms
	while ((waited < QUEUE_TIMEOUT_SECS)); do
		if ! pj=$(pr_json "$num"); then
			log "PR #$num: queue poll at ${waited}s/${QUEUE_TIMEOUT_SECS}s: query failed; retrying"
			sleep "$POLL_SECS"
			waited=$((waited + POLL_SECS))
			continue
		fi
		state=$(jq -r .state <<<"$pj")
		ms=$(jq -r .mergeableState <<<"$pj")
		case "$state" in
			MERGED) log "PR #$num: merged"; return 0 ;;
			CLOSED) log "PR #$num: closed/ejected (state: $state/$ms)"; return 1 ;;
		esac
		case "$ms" in
			dirty | blocked) log "PR #$num: ejected from queue (state: $ms)"; return 1 ;;
		esac
		log "PR #$num: waiting in queue (${waited}s/${QUEUE_TIMEOUT_SECS}s; state: $state/$ms)"
		sleep "$POLL_SECS"
		waited=$((waited + POLL_SECS))
	done
	log "PR #$num: queue entry not resolved within ${QUEUE_TIMEOUT_SECS}s"
	return 2
}

handle_regen() {
	local num=$1 cls=$2 sha=$3 cmd=recreate
	# Fast path: base already at tip — rebase/recreate would not touch content,
	# so don't burn budget or comment. This is the "spinning" case where
	# blocked is due to checks/workflows, not stale base.
	if pr_base_is_tip "$num"; then
		skip_pr "$num" "base already at tip of $(pr_field "$num" baseRef 2>/dev/null || echo "base"); @dependabot $cmd would be no-op"
		return 10
	fi
	local regen_file="${STATE_DIR}/regen-${num}"
	local count=0
	if [[ -f "$regen_file" ]]; then
		count=$(<"$regen_file")
		# guard against corrupted file
		[[ "$count" =~ ^[0-9]+$ ]] || count=0
	fi
	if ((count >= REGEN_MAX)); then
		skip_pr "$num" "regeneration budget spent (max: $REGEN_MAX)"
		return 10
	fi
	count=$((count + 1))
	printf '%s\n' "$count" >"$regen_file"
	[[ "$cls" == "dependabot" ]] && cmd=rebase
	log "PR #$num: triggering @dependabot $cmd (attempt $count/$REGEN_MAX; branch class: $cls)"
	local cr=0
	comment_regen "$num" "$cmd" || cr=$?
	case "$cr" in
		0) ;; # commented
		1) return 11 ;; # dry-run
		2) # base-tip race: comment_regen detected tip after handle_regen's check
			# refund the budget we just consumed
			printf '%s\n' "$((count - 1))" >"$regen_file"
			skip_pr "$num" "base tip race; @dependabot $cmd no-op"
			return 10
			;;
		*) return 10 ;;
	esac
	if ! regen_responded "$num" "$sha"; then
		skip_pr "$num" "dependabot did not regenerate"
		return 10
	fi
	# new head SHA creates fresh workflow runs in waiting/action_required
	approve_pending_workflows "$num"
	return 0
}

drive_pr() {
	local num=$1 pj ms sha cls tries cls_sha=""
	local wait_secs=0

	while :; do
		tries=0
		until pj=$(pr_json "$num"); do
			tries=$((tries + 1))
			if ((tries >= 5)); then
				skip_pr "$num" "GitHub API unreachable"
				return 1
			fi
			log "PR #$num: query failed ($tries/5); retrying in ${POLL_SECS}s"
			sleep "$POLL_SECS"
		done
		ms=$(jq -r .mergeableState <<<"$pj")
		sha=$(jq -r .headRefOid <<<"$pj")
		log "PR #$num: state=$(jq -r .state <<<"$pj") mergeableState=$ms sha=${sha:0:8}"

		if [[ $(jq -r .state <<<"$pj") != "OPEN" ]]; then
			if [[ -n $(jq -r '.mergedAt // ""' <<<"$pj") ]]; then
				record_merged "$num"
				[[ -n "${STATE_DIR:-}" ]] && touch "${STATE_DIR}/merged-${num}" 2>/dev/null || true
			else
				skip_pr "$num" "closed without merging"
			fi
			return 0
		fi

		if [[ "$sha" != "$cls_sha" ]]; then
			cls=$(branch_class "$num")
			log "PR #$num: branch class: $cls (sha: ${sha:0:8})"
			cls_sha=$sha
			wait_secs=0
		fi
		if [[ "$cls" == "human:"* ]]; then
			log "WARNING: PR #$num has commits by '${cls#human:}'; refusing to touch it"
			skip_pr "$num" "human commits by '${cls#human:}' present"
			return 1
		fi

		local regen_rc=0
		case "$ms" in
			clean)
				# clean still may need workflow approval before queue accepts it
				approve_pending_workflows "$num"
				enqueue "$num"
				((DRY_RUN)) && return 0
				if ((!MERGE_QUEUE)); then
					[[ -n "${STATE_DIR:-}" ]] && touch "${STATE_DIR}/merged-${num}" 2>/dev/null || true
					return 0
				fi
				local wrc=0
				wait_queue "$num" || wrc=$?
				case "$wrc" in
					0) record_merged "$num"; [[ -n "${STATE_DIR:-}" ]] && touch "${STATE_DIR}/merged-${num}" 2>/dev/null || true
						# merged SHA changes base for all other PRs in chain — their
						# fresh runs will be in waiting until approved
						return 0 ;;
					1) continue ;;   # ejected: re-evaluate
					*) skip_pr "$num" "merge timed out"; return 1 ;;
				esac
				;;
			dirty | blocked | behind)
				# blocked is often "workflows awaiting approval", not a real
				# check failure — approving is cheaper than recreate and must
				# be tried first. approve_pending_workflows is idempotent, so
				# safe to call before every regen decision.
				approve_pending_workflows "$num"
				# re-poll once cheaply before burning REGEN_MAX
				if pj2=$(pr_json "$num" 2>/dev/null); then
					local ms2
					ms2=$(jq -r .mergeableState <<<"$pj2")
					if [[ "$ms2" != "$ms" ]]; then
						log "PR #$num: mergeableState $ms -> $ms2 after workflow approval; re-evaluating"
						continue
					fi
				fi
				handle_regen "$num" "$cls" "$sha" || regen_rc=$?
				;;
			unknown)
				# GitHub is computing mergeability; poll fast until it resolves.
				log "PR #$num: mergeability computing, re-polling in ${FAST_POLL_SECS}s"
				sleep "$FAST_POLL_SECS"
				continue
				;;
			unstable)
				# unstable often transiently blocked on workflow approval
				approve_pending_workflows "$num"
				wait_secs=$((wait_secs + POLL_SECS))
				if ((wait_secs >= MERGE_TIMEOUT_SECS)); then
					skip_pr "$num" "PR not mergeable within ${MERGE_TIMEOUT_SECS}s (state: $ms)"
					return 1
				fi
				log "PR #$num: checks in progress (${wait_secs}s/${MERGE_TIMEOUT_SECS}s)"
				sleep "$POLL_SECS"
				continue
				;;
			draft)
				skip_pr "$num" "PR is a draft"
				return 1
				;;
			*)
				log "PR #$num: unrecognised mergeable_state '$ms'; polling"
				sleep "$POLL_SECS"
				continue
				;;
		esac

		case "$regen_rc" in
			0) continue ;;   # regenerated: re-evaluate
			11) return 0 ;;  # dry-run plan surfaced
			*) return 1 ;;   # skipped (budget spent)
		esac
	done
}

build_chains() {
	CHAINS=()
	FILE_CHAIN=()
	local num title sig f existing target other
	local -a sigfiles=()
	while IFS=$'\t' read -r num title; do
		[[ "$num" =~ ^[0-9]+$ ]] || continue
		if ((${#INCLUDE[@]})) && ! printf '%s\n' "${INCLUDE[@]}" | grep -qx "$num"; then
			continue
		fi
		# skip PRs whose regen budget is already exhausted (persisted across rounds)
		if [[ -n "${STATE_DIR:-}" && -f "${STATE_DIR}/regen-${num}" ]]; then
			local _c
			_c=$(<"${STATE_DIR}/regen-${num}")
			[[ "$_c" =~ ^[0-9]+$ ]] || _c=0
			if (( _c >= REGEN_MAX )); then
				log "discovered #$num \"$title\" [SKIP: regen budget spent ($REGEN_MAX)]"
				continue
			fi
		fi
		sig=$(pr_files "$num" | sort | paste -sd, -)
		log "discovered #$num \"$title\" [$sig]"
		target=""
		mapfile -t sigfiles < <(tr ',' '\n' <<<"$sig")
		for f in "${sigfiles[@]}"; do
			existing=${FILE_CHAIN[$f]:-}
			[[ -z "$existing" ]] && continue
			if [[ -z "$target" ]]; then
				target=$existing
			elif [[ "$target" != "$existing" ]]; then
				CHAINS[$target]+=" ${CHAINS[$existing]}"
				unset "CHAINS[$existing]"
				for other in "${!FILE_CHAIN[@]}"; do
					[[ "${FILE_CHAIN[$other]}" == "$existing" ]] && FILE_CHAIN[$other]=$target
				done
			fi
		done
		[[ -z "$target" ]] && target="c$num"
		for f in "${sigfiles[@]}"; do FILE_CHAIN[$f]=$target; done
		CHAINS[$target]+=" $num"
	done < <(gh pr list --repo "$REPO" --state open --author app/dependabot \
		--json number,title,createdAt --limit 100 \
		--jq 'sort_by(.createdAt)[] | "\(.number)\t\(.title)"')
}

parse_args() {
	while (($#)); do
		case "$1" in
			--dry-run) DRY_RUN=1 ;;
			--include) shift; INCLUDE+=("$1") ;;
			--poll-secs) shift; POLL_SECS=$1 ;;
			--merge-strategy)
				shift
				case "$1" in
					squash|rebase|merge) MERGE_STRATEGY=$1 ;;
					*) die "--merge-strategy must be one of: squash, rebase, merge" ;;
				esac
				;;
			*) die "unknown argument: $1" ;;
		esac
		shift
	done
}

drain_chain() {
	local sig=$1 num
	# Only the head (oldest) of a chain is eligible per round. Remaining
	# members touch the same files and will necessarily be stale/conflicted
	# until the head merges; processing them in the same round causes a
	# thundering herd of @dependabot recreate (see c176: 176 177 178 179).
	local chain_prs="${CHAINS[$sig]:-}"
	[[ -z "$chain_prs" ]] && { log "chain $sig: empty"; return 0; }
	# intentional word splitting: chain members are bare PR numbers
	# shellcheck disable=SC2086
	set -- $chain_prs
	num=$1
	shift
	local remaining="$*"
	log "chain $sig: starting (head: #$num; queued: $remaining)"
	log "chain $sig: processing PR #$num (remaining:${remaining:-(none)})"
	if ! drive_pr "$num"; then
		local rc=$?
		log "chain $sig: head #$num did not merge (rc=$rc); halting chain for this round"
	fi
	log "chain $sig: done"
}

main() {
	STATE_DIR=$(mktemp -d -t github-dependabot-merge.XXXXXX)
	# shellcheck disable=SC2064
	trap "kill 0 2>/dev/null || true; rm -rf \"$STATE_DIR\"; exit 130" INT TERM
	trap 'rm -rf "$STATE_DIR"' EXIT
	((DRY_RUN)) && log "dry-run: reporting the first planned action per PR, no mutations"
	log "draining dependabot PRs for $REPO"

	probe_merge_queue
	if ((!MERGE_QUEUE)) && [[ -z "$MERGE_STRATEGY" ]]; then
		die "repository has no merge queue; --merge-strategy <squash|rebase|merge> is required"
	fi

	local round=0
	local -a sigs
	local sig
	while :; do
		build_chains
		((${#CHAINS[@]})) || break
		round=$((round + 1))
		mapfile -t sigs < <(printf '%s\n' "${!CHAINS[@]}" | sort)
		log "round $round: ${#sigs[@]} independent chain(s): ${sigs[*]}"

		# workflows for every head start in waiting/action_required after any
		# file-touching transition (prior merges, rebases, recreates). Approve
		# up-front so blocked doesn't immediately burn REGEN_MAX.
		for sig in "${sigs[@]}"; do
			head=$(awk '{print $1}' <<<"${CHAINS[$sig]}")
			[[ -n "$head" ]] && approve_pending_workflows "$head"
		done

		# clear per-round merge markers; handle_regen counters persist via STATE_DIR/regen-*
		rm -f "${STATE_DIR}"/merged-* 2>/dev/null || true

		for sig in "${sigs[@]}"; do
			log "spawning chain driver for $sig (PRs:${CHAINS[$sig]})"
			drain_chain "$sig" &
		done
		log "waiting for ${#sigs[@]} chain driver(s) to finish"
		wait || log "WARNING: a chain driver exited abnormally"
		log "all chain drivers finished"

		# Re-scan only when using a merge queue: PRs can be ejected and need
		# re-queuing. For direct merges every PR is handled exactly once.
		if ((DRY_RUN)) || ((!MERGE_QUEUE)); then
			break
		fi

		# progress check: if nothing merged and no chains will make progress, stop
		# (prevents infinite loop on permanently blocked PRs; regen budget is
		# file-backed so exhausted PRs are filtered in build_chains next round)
		local merged=0
		# shellcheck disable=SC2044
		for _m in "${STATE_DIR}"/merged-*; do [[ -e "$_m" ]] && { merged=1; break; }; done
		if (( ! merged )); then
			# check if any remaining chain head is still retryable (regen budget left)
			local retryable=0
			for sig in "${sigs[@]}"; do
				# chain head is first number in CHAINS[$sig] from this round
				local head
				head=$(awk '{print $1}' <<<"${CHAINS[$sig]}")
				[[ -z "$head" ]] && continue
				if [[ ! -f "${STATE_DIR}/regen-${head}" ]]; then
					retryable=1; break
				fi
				local c
				c=$(<"${STATE_DIR}/regen-${head}")
				[[ "$c" =~ ^[0-9]+$ ]] || c=0
				(( c < REGEN_MAX )) && { retryable=1; break; }
			done
			if (( ! retryable )); then
				log "no merges in round $round and no retryable heads remain; stopping"
				break
			fi
			# else: at least one head regenerated this round and might become
			# clean on next poll without extra recreate — give it another round
			log "no merges in round $round but retryable heads remain; re-scanning"
		else
			log "round $round produced merges; re-scanning for next heads"
		fi
	done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	parse_args "$@"
	main
fi
