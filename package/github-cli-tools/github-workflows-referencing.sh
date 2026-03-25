#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Search GitHub Actions workflow files for matching action/reusable references or CLI commands.

Usage:
  github-workflows-referencing.sh [options]

Matchers (at least one required, all repeatable):
  --action <owner/repo[/path]>                 Match step-level uses references (any version)
  --action-org <org>                           Match any step-level action from this org
  --command <text>                             Match step-level run script command usage
  --command-mode <invoked|contains>            Command matching mode (default: invoked)
                                               invoked: match command-like tokens at shell
                                               command boundaries in run scripts
                                               contains: substring match in run script text
  --reusable <owner/repo/.github/workflows/file.yml>
                                               Match job-level reusable workflow calls (any version)

Filters:
  --disabled-filter <all|exclude|only>         Filter jobs with an if: expression containing
                                               a provably-false branch (default: all)
  --exclude-disabled                           Shortcut for --disabled-filter exclude
  --only-disabled                              Shortcut for --disabled-filter only

Other options:
  --path <dir>                                 Root directory to scan (repeatable, default: .)
  -h, --help                                   Show help

Requirements:
  - yq must be mikefarah/yq v4+

Output columns (TSV):
  kind, repo, workflow, job_id, job_name, disabled, step, step_name, reference, detail

Examples:
  github-workflows-referencing.sh --path ~/src --action actions/checkout
  github-workflows-referencing.sh --path ~/src --action-org aquasecurity --exclude-disabled
  github-workflows-referencing.sh --path ~/src --command trivy
  github-workflows-referencing.sh --path ~/src \
    --reusable my-org/my-repo/.github/workflows/release.yml
EOF
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Error: required command not found: $command_name" >&2
    exit 1
  fi
}

require_mikefarah_yq() {
  require_command yq

  local yq_version
  if ! yq_version="$(yq --version 2>&1)"; then
    echo "Error: failed to execute yq --version" >&2
    exit 1
  fi

  if [[ "$yq_version" != *"mikefarah"* && "$yq_version" != *"github.com/mikefarah/yq"* ]]; then
    echo "Error: unsupported yq implementation detected: $yq_version" >&2
    echo "Please install mikefarah/yq v4+ and ensure it is first in PATH." >&2
    exit 1
  fi
}

json_array_from_args() {
  jq -nc '$ARGS.positional' --args "$@"
}

declare -a ROOTS=()
DISABLED_FILTER="all"
COMMAND_MODE="invoked"

declare -a ACTION_REFS=()
declare -a ACTION_ORGS=()
declare -a COMMAND_PATTERNS=()
declare -a REUSABLE_REFS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      ROOTS+=("${2:-}")
      shift 2
      ;;
    --action)
      ACTION_REFS+=("${2:-}")
      shift 2
      ;;
    --action-org)
      ACTION_ORGS+=("${2:-}")
      shift 2
      ;;
    --command)
      COMMAND_PATTERNS+=("${2:-}")
      shift 2
      ;;
    --command-mode)
      COMMAND_MODE="${2:-}"
      shift 2
      ;;
    --reusable)
      REUSABLE_REFS+=("${2:-}")
      shift 2
      ;;
    --disabled-filter)
      DISABLED_FILTER="${2:-}"
      shift 2
      ;;
    --exclude-disabled)
      DISABLED_FILTER="exclude"
      shift
      ;;
    --only-disabled)
      DISABLED_FILTER="only"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${#ROOTS[@]} -eq 0 ]]; then
  ROOTS=(".")
fi

for root in "${ROOTS[@]}"; do
  if [[ -z "$root" ]]; then
    echo "Error: --path cannot be empty." >&2
    exit 1
  fi

  if [[ ! -d "$root" ]]; then
    echo "Error: path does not exist: $root" >&2
    exit 1
  fi
done

if [[ "$DISABLED_FILTER" != "all" && "$DISABLED_FILTER" != "exclude" && "$DISABLED_FILTER" != "only" ]]; then
  echo "Error: --disabled-filter must be one of: all, exclude, only" >&2
  exit 1
fi

if [[ "$COMMAND_MODE" != "invoked" && "$COMMAND_MODE" != "contains" ]]; then
  echo "Error: --command-mode must be one of: invoked, contains" >&2
  exit 1
fi

if [[ ${#ACTION_REFS[@]} -eq 0 && ${#ACTION_ORGS[@]} -eq 0 && ${#COMMAND_PATTERNS[@]} -eq 0 && ${#REUSABLE_REFS[@]} -eq 0 ]]; then
  echo "Error: provide at least one matcher (--action, --action-org, --command, --reusable)." >&2
  usage
  exit 1
fi

for item in "${ACTION_REFS[@]}" "${ACTION_ORGS[@]}" "${COMMAND_PATTERNS[@]}" "${REUSABLE_REFS[@]}"; do
  if [[ -z "$item" ]]; then
    echo "Error: matcher values cannot be empty." >&2
    exit 1
  fi
done

require_mikefarah_yq
require_command jq
require_command find

action_refs_json="$(json_array_from_args "${ACTION_REFS[@]}")"
action_orgs_json="$(json_array_from_args "${ACTION_ORGS[@]}")"
command_patterns_json="$(json_array_from_args "${COMMAND_PATTERNS[@]}")"
reusable_refs_json="$(json_array_from_args "${REUSABLE_REFS[@]}")"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

processed=0

while IFS= read -r -d '' workflow_file; do
  rel_workflow="$workflow_file"
  matched_root=""

  for root in "${ROOTS[@]}"; do
    if [[ "$workflow_file" == "$root/"* ]]; then
      matched_root="$root"
      rel_workflow="${workflow_file#"$root"/}"
      break
    fi
  done

  repo_path="$workflow_file"
  repo_path="${repo_path%/.github/workflows/*}"
  repo_name="$(basename "$repo_path")"

  if ! workflow_json="$(yq -o=json '.' "$workflow_file" 2>/dev/null)"; then
    echo "Warning: unable to parse YAML: $workflow_file" >&2
    continue
  fi

  printf '%s\n' "$workflow_json" | jq -r \
    --arg workflow "$rel_workflow" \
    --arg repo "$repo_name" \
    --arg disabledFilter "$DISABLED_FILTER" \
    --arg commandMode "$COMMAND_MODE" \
    --argjson actionRefs "$action_refs_json" \
    --argjson actionOrgs "$action_orgs_json" \
    --argjson commands "$command_patterns_json" \
    --argjson reusableRefs "$reusable_refs_json" '
      def normalize_use: split("@")[0];

      def normalize_if:
        .
        | gsub("^\\s*\\$\\{\\{"; "")
        | gsub("\\}\\}\\s*$"; "")
        | gsub("\\s+"; " ")
        | gsub("^ "; "")
        | gsub(" $"; "");

      # Conservative disabled detection.
      # Mark disabled only when we can confidently prove the condition is always false.
      def is_disabled_job:
        (.if? // "") as $if
        | ($if | type == "string")
        and (
          (($if | normalize_if) as $expr
            | ($expr | test("^\\(*\\s*false\\s*\\)*$"; "i"))
            or (
              ($expr | contains("||") | not)
              and ($expr | test("(^|&&)\\s*\\(*\\s*false\\s*\\)*\\s*($|&&)"; "i"))
            )
          )
        );

      def disabled_ok:
        if $disabledFilter == "all" then true
        elif $disabledFilter == "exclude" then (not)
        elif $disabledFilter == "only" then .
        else true
        end;

      def match_action:
        . as $uses
        | ($uses | type == "string")
        and (
          (($actionRefs | length) > 0 and any($actionRefs[]; . as $ref | ($uses | normalize_use | startswith($ref))))
          or
          (($actionOrgs | length) > 0 and (
            ($uses | normalize_use | split("/")) as $parts
            | ($parts | length) >= 2
            and any($actionOrgs[]; $parts[0] == .)
          ))
        );

      def match_reusable:
        . as $uses
        | ($uses | type == "string")
        and (($reusableRefs | length) > 0 and any($reusableRefs[]; ($uses | normalize_use) == .));

      def regex_escape:
        .
        | gsub("\\\\"; "\\\\\\\\")
        | gsub("\\."; "\\\\.")
        | gsub("\\^"; "\\\\^")
        | gsub("\\$"; "\\\\$")
        | gsub("\\*"; "\\\\*")
        | gsub("\\+"; "\\\\+")
        | gsub("\\?"; "\\\\?")
        | gsub("\\("; "\\\\(")
        | gsub("\\)"; "\\\\)")
        | gsub("\\["; "\\\\[")
        | gsub("\\]"; "\\\\]")
        | gsub("\\{"; "\\\\{")
        | gsub("\\}"; "\\\\}")
        | gsub("\\|"; "\\\\|");

      def match_command_invoked:
        . as $run
        | any($commands[];
          . as $needle
          | ($needle | regex_escape) as $re
          | ($run | test("(^|[;|&][;|&]?|\\n)\\s*" + $re + "([[:space:]]|$)"; "i"))
        );

      def match_command_contains:
        . as $run
        | any($commands[]; . as $needle | ($run | ascii_downcase | contains($needle | ascii_downcase)));

      def match_command:
        (. | type == "string")
        and (($commands | length) > 0)
        and (
          if $commandMode == "contains" then
            match_command_contains
          else
            match_command_invoked
          end
        );

      def first_line: split("\n")[0];

      [
        (.jobs // {} | to_entries[]?) as $job
        | ($job.value | is_disabled_job) as $disabled
        | select($disabled | disabled_ok)
        | (
            ($job.value.steps // [] | to_entries[]?
              | . as $step
              | select($step.value.uses | match_action)
              | {
                  kind: "action",
                  workflow: $workflow,
                  repo: $repo,
                  job_id: $job.key,
                  job_name: ($job.value.name // ""),
                  disabled: $disabled,
                  step: (($step.key + 1) | tostring),
                  step_name: ($step.value.name // ""),
                  reference: ($step.value.uses // ""),
                  detail: ""
                }
            ),
            ($job.value.steps // [] | to_entries[]?
              | . as $step
              | select($step.value.run | match_command)
              | {
                  kind: "command",
                  workflow: $workflow,
                  repo: $repo,
                  job_id: $job.key,
                  job_name: ($job.value.name // ""),
                  disabled: $disabled,
                  step: (($step.key + 1) | tostring),
                  step_name: ($step.value.name // ""),
                  reference: "",
                  detail: ($step.value.run | first_line)
                }
            ),
            (if ($job.value.uses | match_reusable) then
              {
                kind: "reusable-workflow",
                workflow: $workflow,
                repo: $repo,
                job_id: $job.key,
                job_name: ($job.value.name // ""),
                disabled: $disabled,
                step: "",
                step_name: "",
                reference: ($job.value.uses // ""),
                detail: ""
              }
             else empty end)
          )
      ]
      | .[]
      | [
          .kind,
          .repo,
          .workflow,
          .job_id,
          .job_name,
          (if .disabled then "yes" else "no" end),
          .step,
          .step_name,
          .reference,
          .detail
        ]
      | @tsv
    ' >>"$tmp_file"

  processed=$((processed + 1))
  if (( processed % 200 == 0 )); then
    echo "Processed $processed workflow files..." >&2
  fi
done < <(
  declare -A seen_files=()
  for root in "${ROOTS[@]}"; do
    while IFS= read -r -d '' candidate; do
      if [[ -z "${seen_files[$candidate]+x}" ]]; then
        seen_files[$candidate]=1
        printf '%s\0' "$candidate"
      fi
    done < <(find "$root" -type f \( -path '*/.github/workflows/*.yml' -o -path '*/.github/workflows/*.yaml' \) -print0)
  done
)

echo -e "kind\trepo\tworkflow\tjob_id\tjob_name\tdisabled\tstep\tstep_name\treference\tdetail"

if [[ -s "$tmp_file" ]]; then
  sort "$tmp_file"
else
  echo "No matching references found." >&2
fi
