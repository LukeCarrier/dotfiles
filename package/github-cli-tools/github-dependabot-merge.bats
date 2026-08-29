# Tests for github-dependabot-merge.sh.
#
# gh is intercepted by a stub serving JSON fixtures from $FAKE and recording
# mutations (regens/merges) as log files there. Only fast terminal paths are
# exercised end-to-end; the sleep-poll waiters are thin wrappers around the
# predicates tested here.

bats_require_minimum_version 1.5.0

# Folded from .github/workflows/test_helper/common — was a no-op shim to make
# `nix run nixpkgs#bats` work without flake's BATS_LIB_PATH. Keep tests
# self-contained; no external lib needed.
_common_setup() { :; }

SCRIPT="${BATS_TEST_DIRNAME}/github-dependabot-merge.sh"

# Source at load time with the repo pinned: sourcing inside setup() would be
# too late for the script's top-level defaults, and function-scoped sourcing
# turns its globals into locals.
export GITHUB_REPO="test/repo"
source "$SCRIPT"

setup() {
	_common_setup
	FAKE="$BATS_TEST_TMPDIR/fake"
	mkdir -p "$FAKE"
	# file-backed regen budget lives in STATE_DIR; point it at the per-test fake
	# dir so tests are isolated and don't touch /regen-*.
	export STATE_DIR="$FAKE"

	# bats sources this file from inside one of its own functions, so the
	# script's top-level `declare -A` maps end up as transient locals. Restore
	# them as real globals (and reset per test).
	declare -g -A CHAINS=() FILE_CHAIN=()

	_emit() {
		local file=$1
		shift
		local -a a=("$@") i prog=""
		for i in "${!a[@]}"; do
			case "${a[$i]}" in
				--jq|-q) prog="${a[$((i + 1))]}" ;;
			esac
		done
		if [[ -n "$prog" ]]; then
			jq -r "$prog" <"$file"
		else
			cat "$file"
		fi
	}

	gh() {
		case "$1" in
			api) _stub_api "${@:2}" ;;
			pr)  _stub_pr  "${@:2}" ;;
			*)   fail "unexpected gh subcommand: $*" ;;
		esac
	}

	_stub_api() {
		local arg path=""
		for arg in "$@"; do
			case "$arg" in
				repos/*|graphql) path="$arg"; break ;;
			esac
		done
		# fall back to $1 for backwards compat
		[[ -z "$path" ]] && path="$1"
		path="${path#repos/test/repo/}"
		case "$path" in
			pulls/*/files)
				local num="${path#pulls/}"; num="${num%%/*}"
				if [[ -f "$FAKE/files-$num.json" ]]; then
					_emit "$FAKE/files-$num.json" "${@:2}"
				else
					_emit "$FAKE/files.json" "${@:2}"
				fi ;;
			pulls/*/commits)
				local num="${path#pulls/}"; num="${num%%/*}"
				_emit "$FAKE/commits-$num.json" "${@:2}" ;;
			actions/runs/*/approve)
				# POST .../actions/runs/<id>/approve
				echo "$path" >>"$FAKE/approved.log"
				printf '{}' | _emit /dev/stdin "${@:2}" ;;
			git/refs/heads/*)
				# base-tip check: return main-tip-sha unless overridden by fixture
				if [[ -f "$FAKE/tip-${path##*/}.json" ]]; then
					_emit "$FAKE/tip-${path##*/}.json" "${@:2}"
				else
					# default tip differs from pr base so pr_base_is_tip is false
					printf '{"object": {"sha": "main-tip-sha-not-base"}}' | _emit /dev/stdin "${@:2}"
				fi ;;
			actions/runs*)
				# approve_pending_workflows: no pending runs by default
				if [[ -f "$FAKE/runs.json" ]]; then
					_emit "$FAKE/runs.json" "${@:2}"
				else
					printf '{"workflow_runs": []}' | _emit /dev/stdin "${@:2}"
				fi ;;
			pulls/*)
				local num="${path#pulls/}"; num="${num%%/*}"
				_emit "$FAKE/pr-$num.json" "${@:2}" ;;
			graphql)
				printf '{"data":{"repository":{"mergeQueue":null}}}' ;;
			*) fail "unexpected api path: $path" ;;
		esac
	}

	_stub_pr() {
		case "$1" in
			list) _emit "$FAKE/pr-list.json" "${@:2}" ;;
			view)
				# approve_pending_workflows needs headRefName
				local num="$2" branch="dependabot/branch-$num"
				if [[ -f "$FAKE/branch-$num" ]]; then
					branch=$(cat "$FAKE/branch-$num")
				fi
				# honour --json / -q plumbing from caller via _emit
				printf '{"headRefName": "%s"}' "$branch" | _emit /dev/stdin "${@:3}" ;;
			comment)
				local -a cargs=("$@") i body=""
				for i in "${!cargs[@]}"; do
					[[ "${cargs[$i]}" == "--body" ]] && body="${cargs[$((i + 1))]}"
				done
				echo "$2 $body" >>"$FAKE/regen.log" ;;
			merge)
				if [[ -f "$FAKE/refuse-merge" ]]; then return 1; fi
				echo "$2" >>"$FAKE/merges.log" ;;
			*) fail "unexpected pr subcommand: $1" ;;
		esac
	}
}

fixture() { printf '%s' "$2" >"$FAKE/$1"; }

# pr_fixture NUM STATE MERGEABLE_STATE HEAD [MERGED_AT] [BASE_REF] [BASE_SHA]
# STATE: open | closed (merged_at non-null implies merged)
# MERGEABLE_STATE: clean | dirty | blocked | behind | unstable | unknown | draft
pr_fixture() {
	local num=$1 state=$2 ms=$3 sha=${4:-abc0000000000000000000000000000000000001}
	local merged_at=${5:-null}
	local base_ref=${6:-main}
	local base_sha=${7:-base-sha-not-tip}
	fixture "pr-$num.json" \
		"{\"number\": $num, \"state\": \"$state\", \"merged_at\": $merged_at, \"mergeable_state\": \"$ms\", \"head\": {\"sha\": \"$sha\"}, \"base\": {\"ref\": \"$base_ref\", \"sha\": \"$base_sha\"}, \"title\": \"PR $num\"}"
}

branch_commits_fixture() { # NUM LOGIN...   'null' -> unknown login
	local num=$1 out="[" first=1 login
	shift
	for login in "$@"; do
		((first)) || out+=","
		first=0
		if [[ "$login" == "null" ]]; then
			out+="{\"sha\": \"s$first$login\", \"author\": null, \"commit\": {\"author\": {\"name\": \"Someone\"}}}"
		else
			out+="{\"sha\": \"s$first\", \"author\": {\"login\": \"$login\"}, \"commit\": {\"author\": {\"name\": \"$login\"}}}"
		fi
	done
	fixture "commits-$num.json" "$out]"
}

@test "parse_args recognises flags" {
	parse_args --dry-run --include 147 --include 171 --poll-secs 5 --merge-strategy squash
	[[ "$DRY_RUN" == 1 ]]
	[[ "${INCLUDE[0]}" == 147 && "${INCLUDE[1]}" == 171 ]]
	[[ "$POLL_SECS" == 5 ]]
	[[ "$MERGE_STRATEGY" == squash ]]
}

@test "branch_class: pure dependabot branch classifies as dependabot" {
	branch_commits_fixture 143 dependabot[bot]
	run branch_class 143
	[[ "$output" == "dependabot" ]]
}

@test "branch_class: other bot commit forces other-bot classification" {
	branch_commits_fixture 144 dependabot[bot] github-actions[bot]
	run branch_class 144
	[[ "$output" == "other-bot" ]]
}

@test "branch_class: any human commit is detected by login" {
	branch_commits_fixture 145 dependabot[bot] LukeCarrier
	run branch_class 145
	[[ "$output" == "human:LukeCarrier" ]]
}

@test "branch_class: unknown login falls back to the git author name" {
	branch_commits_fixture 146 null
	run branch_class 146
	[[ "$output" == "human:Someone" ]]
}

@test "branch_class: unparsable history fails safe as human" {
	fixture commits-149.json '[]'
	run branch_class 149
	[[ "$output" == "human:<unparsable>" ]]
}

@test "build_chains groups overlapping file sets and keeps disjoint ones apart" {
	fixture pr-list.json "$(cat <<'EOF'
[
 {"number": 149, "title": "js-yaml", "createdAt": "2026-08-01T00:00:00Z"},
 {"number": 143, "title": "glob", "createdAt": "2026-07-30T00:00:00Z"},
 {"number": 151, "title": "body-parser", "createdAt": "2026-08-01T01:00:00Z"},
 {"number": 144, "title": "serde_json", "createdAt": "2026-07-30T01:00:00Z"}
]
EOF
)"
	fixture files-143.json '[{"filename": "Cargo.lock"}, {"filename": "nix/flake.nix"}]'
	fixture files-144.json '[{"filename": "Cargo.lock"}, {"filename": "nix/flake.nix"}]'
	fixture files-149.json '[{"filename": "docs/yarn.lock"}]'
	fixture files-151.json '[{"filename": "docs/package.json"}, {"filename": "docs/yarn.lock"}]'
	build_chains >/dev/null

	[[ ${#CHAINS[@]} -eq 2 ]]
	local cargo_chain="" docs_chain="" k
	for k in "${!CHAINS[@]}"; do
		case "${CHAINS[$k]}" in
			*143*) cargo_chain="${CHAINS[$k]}" ;;
			*149*) docs_chain="${CHAINS[$k]}" ;;
		esac
	done
	[[ "$cargo_chain" == " 143 144" ]]
	[[ "$docs_chain" == " 149 151" ]]
}

@test "drive_pr records a merged PR and stops" {
	pr_fixture 147 closed clean abc147 '"2026-08-23T12:00:00Z"'
	run --separate-stderr drive_pr 147
	[[ $stderr == *"PR #147: merged"* ]]
}

@test "drive_pr refuses branches with human commits" {
	pr_fixture 145 open dirty abc145
	branch_commits_fixture 145 LukeCarrier
	run --separate-stderr drive_pr 145
	[[ $stderr == *"human commits by 'LukeCarrier' present"* ]]
	[[ ! -e "$FAKE/regen.log" ]]
}

@test "drive_pr skips once the regeneration budget is spent" {
	REGEN_MAX=0
	pr_fixture 144 open dirty abc144
	branch_commits_fixture 144 dependabot[bot] github-actions[bot]
	run --separate-stderr drive_pr 144
	[[ $stderr == *"regeneration budget spent"* ]]
	[[ ! -e "$FAKE/regen.log" ]]
}

@test "drive_pr skips draft PRs" {
	pr_fixture 148 open draft abc148
	branch_commits_fixture 148 dependabot[bot]
	run --separate-stderr drive_pr 148
	[[ $stderr == *"PR is a draft"* ]]
	[[ ! -e "$FAKE/merges.log" ]]
}

@test "dry-run plans a rebase for pure-dependabot dirty PRs" {
	DRY_RUN=1
	pr_fixture 143 open dirty abc143
	branch_commits_fixture 143 dependabot[bot]
	run --separate-stderr drive_pr 143
	[[ $stderr == *"would comment '@dependabot rebase'"* ]]
	[[ ! -e "$FAKE/regen.log" ]]
}

@test "dry-run plans a recreate for branches carrying other bots' commits" {
	DRY_RUN=1
	pr_fixture 158 open dirty abc158
	branch_commits_fixture 158 dependabot[bot] github-actions[bot]
	run --separate-stderr drive_pr 158
	[[ $stderr == *"would comment '@dependabot recreate'"* ]]
	[[ ! -e "$FAKE/regen.log" ]]
}

@test "dry-run plans a merge for clean PRs (no merge queue)" {
	DRY_RUN=1
	MERGE_QUEUE=0
	MERGE_STRATEGY=rebase
	pr_fixture 147 open clean abc147
	branch_commits_fixture 147 dependabot[bot]
	run --separate-stderr drive_pr 147
	[[ $stderr == *"would merge directly (--rebase)"* ]]
	[[ ! -e "$FAKE/merges.log" ]]
}

@test "dry-run plans an enqueue for clean PRs (merge queue present)" {
	DRY_RUN=1
	MERGE_QUEUE=1
	pr_fixture 147 open clean abc147
	branch_commits_fixture 147 dependabot[bot]
	run --separate-stderr drive_pr 147
	[[ $stderr == *"would enqueue into merge queue"* ]]
	[[ ! -e "$FAKE/merges.log" ]]
}

@test "comment_regen is no-op when base is already tip of main" {
	# base sha equals tip so rebase would not touch content
	pr_fixture 200 open blocked abc200 null main main-tip-sha-not-base
	fixture "tip-main.json" '{"object": {"sha": "main-tip-sha-not-base"}}'
	branch_commits_fixture 200 dependabot[bot]
	run --separate-stderr drive_pr 200
	[[ $stderr == *"base already at tip"* ]]
	[[ ! -e "$FAKE/regen.log" ]]
}

@test "approve_pending_workflows is called after file-touching transitions" {
	# clean PR triggers approval before enqueue; blocked with base tip also triggers approval path
	pr_fixture 202 open clean abc202
	branch_commits_fixture 202 dependabot[bot]
	fixture "runs.json" '{"workflow_runs": [{"id": 123, "event": "pull_request"}]}'
	run --separate-stderr drive_pr 202
	[[ $stderr == *"approving workflow run 123"* ]]
	[[ -f "$FAKE/approved.log" ]]
	grep -q "123/approve" "$FAKE/approved.log"
}
