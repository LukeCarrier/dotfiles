set -euo pipefail

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf 'Usage: nx-pick [Nx target arguments...]\n\nSelect a project, target, and available configuration with fzf, then run it once.\nExample: nx-pick --configuration=production\n'
  exit 0
fi

directory="$PWD"
nx=""
while :; do
  if [[ -x "$directory/node_modules/.bin/nx" ]]; then
    nx="$directory/node_modules/.bin/nx"
    break
  fi
  [[ "$directory" == / ]] && break
  directory="${directory%/*}"
  directory="${directory:-/}"
done

if [[ -z "$nx" ]]; then
  nx="$(command -v nx)" || {
    printf 'nx-pick: Nx not found; install the workspace dependencies or put nx on PATH.\n' >&2
    exit 127
  }
fi

nx_show() {
  local output status
  if output="$(NX_TUI=false FORCE_COLOR=0 "$nx" show "$@" --json)"; then
    printf '%s\n' "$output"
  else
    status=$?
    printf 'nx-pick: Nx discovery failed (%s).\n%s\n' "$*" "$output" >&2
    return "$status"
  fi
}

pick() {
  FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' fzf --no-multi --prompt "$1"
}

projects_json="$(nx_show projects)"
projects="$(jq -r 'sort[]' <<< "$projects_json")"
if [[ -z "$projects" ]]; then
  printf 'nx-pick: No projects found.\n' >&2
  exit 1
fi

project="$(pick 'Project> ' <<< "$projects")"
[[ -n "$project" ]] || exit 1

project_json="$(nx_show project "$project")"
targets="$(jq -r '.targets // {} | keys[]' <<< "$project_json")"
if [[ -z "$targets" ]]; then
  printf 'nx-pick: Project %s has no targets.\n' "$project" >&2
  exit 1
fi

target="$(pick "Target ($project)> " <<< "$targets")"
[[ -n "$target" ]] || exit 1

configuration_args=()
explicit_configuration=false
for argument in "$@"; do
  case "$argument" in
    --) break ;;
    --configuration|--configuration=*|-c|-c=*)
      explicit_configuration=true
      break
      ;;
  esac
done

if [[ "$explicit_configuration" == false ]]; then
  configurations="$(jq -r --arg target "$target" '.targets[$target].configurations // {} | keys[]' <<< "$project_json")"
  if [[ -n "$configurations" ]]; then
    default_configuration="$(jq -r --arg target "$target" '.targets[$target].defaultConfiguration // empty' <<< "$project_json")"
    default_label="(default: ${default_configuration:-base options})"
    configuration="$(pick 'Configuration> ' <<< "$default_label
$configurations")"
    [[ -n "$configuration" ]] || exit 1
    if [[ "$configuration" != "$default_label" ]]; then
      configuration_args=(--configuration "$configuration")
    fi
  fi
fi

exec "$nx" run "$project:$target" "${configuration_args[@]}" "$@"
