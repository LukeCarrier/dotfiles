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
			mergeableState: .mergeable_state
		}' "$@"
}

pr_field() { pr_json "$1" | jq -r ".$2"; }

pr_files() { api "pulls/$1/files" --paginate --jq '.[].filename'; }

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

comment_regen() {
	local num=$1 cmd=$2
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
	if ((REGEN_COUNT >= REGEN_MAX)); then
		skip_pr "$num" "regeneration budget spent (max: $REGEN_MAX)"
		return 10
	fi
	REGEN_COUNT=$((REGEN_COUNT + 1))
	[[ "$cls" == "dependabot" ]] && cmd=rebase
	log "PR #$num: triggering @dependabot $cmd (attempt $REGEN_COUNT/$REGEN_MAX; branch class: $cls)"
	comment_regen "$num" "$cmd" || return 11 # dry-run: stop here
	if ! regen_responded "$num" "$sha"; then
		skip_pr "$num" "dependabot did not regenerate"
		return 10
	fi
	return 0
}

drive_pr() {
	local num=$1 pj ms sha cls tries cls_sha=""
	local wait_secs=0
	REGEN_COUNT=0

	while :; do
		tries=0
		until pj=$(pr_json "$num"); do
			tries=$((tries + 1))
			if ((tries >= 5)); then
				skip_pr "$num" "GitHub API unreachable"
				return 0
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
			return 0
		fi

		local regen_rc=0
		case "$ms" in
			clean)
				enqueue "$num"
				((DRY_RUN)) && return 0
				((!MERGE_QUEUE)) && return 0  # direct merge: already done
				case "$(wait_queue "$num")" in
					0) record_merged "$num"; return 0 ;;
					1) continue ;;   # ejected: re-evaluate
					*) skip_pr "$num" "merge timed out"; return 0 ;;
				esac
				;;
			dirty | blocked | behind)
				# dirty: conflict; blocked: checks failed; behind: branch stale
				handle_regen "$num" "$cls" "$sha" || regen_rc=$?
				;;
			unknown)
				# GitHub is computing mergeability; poll fast until it resolves.
				log "PR #$num: mergeability computing, re-polling in ${FAST_POLL_SECS}s"
				sleep "$FAST_POLL_SECS"
				continue
				;;
			unstable)
				wait_secs=$((wait_secs + POLL_SECS))
				if ((wait_secs >= MERGE_TIMEOUT_SECS)); then
					skip_pr "$num" "PR not mergeable within ${MERGE_TIMEOUT_SECS}s (state: $ms)"
					return 0
				fi
				log "PR #$num: checks in progress (${wait_secs}s/${MERGE_TIMEOUT_SECS}s)"
				sleep "$POLL_SECS"
				continue
				;;
			draft)
				skip_pr "$num" "PR is a draft"
				return 0
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
			*) return 0 ;;   # skipped
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
	log "chain $sig: starting (PRs:${CHAINS[$sig]})"
	while [[ -n "${CHAINS[$sig]:-}" ]]; do
		# intentional word splitting: chain members are bare PR numbers
		# shellcheck disable=SC2086
		set -- ${CHAINS[$sig]}
		num=$1
		shift
		CHAINS[$sig]=$*
		log "chain $sig: processing PR #$num (remaining:${CHAINS[$sig]:-(none)})"
		drive_pr "$num"
	done
	log "chain $sig: done"
}

main() {
	trap 'kill 0; exit 130' INT TERM
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
	done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	parse_args "$@"
	main
fi
