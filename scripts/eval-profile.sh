#!/usr/bin/env bash
set -euo pipefail

# Profile Nix flake evaluation for a single attribute: wall-clock timing
# (warm eval-cache and cold/no-cache), evaluator statistics and a sampling
# flamegraph.
#
# Usage:
#   scripts/eval-profile.sh [-w warm-runs] [-c cold-runs] [-f hz] <target>
#   scripts/eval-profile.sh --all
#
# Targets:
#   nixos:<host>      nixosConfigurations.<host>.config.system.build.toplevel
#   darwin:<host>     darwinConfigurations.<host>.config.system.build.toplevel
#   home:<config>     homeConfigurations."<config>".activationPackage
#   attr:<attrpath>   any attribute, evaluated verbatim (e.g. attr:devShells.x86_64-linux.default)

flake=.
warm_runs=2
cold_runs=1
frequency=99
all=0
target=

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -w) warm_runs="$2"; shift 2 ;;
    -c) cold_runs="$2"; shift 2 ;;
    -f) frequency="$2"; shift 2 ;;
    --all) all=1; shift ;;
    -h | --help) usage 0 ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *)
      [ -z "$target" ] || { echo "only one target at a time" >&2; usage; }
      target="$1"
      shift
      ;;
  esac
done

resolve_attr() {
  case "$1" in
    nixos:*) printf 'nixosConfigurations.%s.config.system.build.toplevel.drvPath' "${1#nixos:}" ;;
    darwin:*) printf 'darwinConfigurations.%s.config.system.build.toplevel.drvPath' "${1#darwin:}" ;;
    home:*) printf 'homeConfigurations."%s".activationPackage.drvPath' "${1#home:}" ;;
    attr:*) printf '%s' "${1#attr:}" ;;
    *) return 1 ;;
  esac
}

list_targets() {
  local output=$1 kind=$2
  nix eval --json --apply 'builtins.attrNames' "$flake#$output" 2>/dev/null |
    jq -r --arg kind "$kind" '.[] | "\($kind):\(.)"'
}

now_ns() { date +%s%N; }

elapsed() {
  awk -v s="$1" -v e="$2" 'BEGIN { printf "%.2f", (e - s) / 1e9 }'
}

find_flamegraph() {
  if command -v flamegraph.pl >/dev/null 2>&1; then
    command -v flamegraph.pl
    return
  fi
  local out rev
  # Prefer the locked nixpkgs revision from flake.lock over the registry.
  rev=$(jq -r '.nodes["nixpkgs-unstable"].locked.rev // empty' flake.lock 2>/dev/null || true)
  if [ -n "$rev" ]; then
    out=$(nix build --no-link --print-out-paths "github:NixOS/nixpkgs/$rev#flamegraph" 2>/dev/null | tail -n1) || out=
  fi
  if [ -z "${out:-}" ]; then
    out=$(nix build --no-link --print-out-paths 'nixpkgs#flamegraph' 2>/dev/null | tail -n1) || out=
  fi
  [ -n "${out:-}" ] || return 1
  printf '%s/bin/flamegraph.pl' "$out"
}

profile_one() {
  target=$1
  local attr
  if ! attr=$(resolve_attr "$target"); then
    echo "cannot parse target: $target" >&2
    usage
  fi

  local name out
  name=$(printf '%s' "$target" | tr ':@/' '___')
  out="profile/$name"
  mkdir -p "$out"

  {
    echo "target: $target"
    echo "attr: $attr"
    echo "date: $(date -Is)"
    echo "nix: $(nix --version)"
    echo "git: $(git rev-parse --short HEAD 2>/dev/null || echo n/a)"
    echo "eval-profiler-frequency: $frequency"
  } >"$out/meta.txt"

  local stderr_file start end
  stderr_file=$(mktemp)

  # Warm runs: `nix build --dry-run` mirrors nh/nixos-rebuild/home-manager,
  # which all go through `nix build` and therefore the flake eval cache.
  # (`nix eval` does not read the eval cache, so timing it warm is useless.)
  local build_attr="${attr%.drvPath}"
  : >"$out/timing-warm.txt"
  local i seconds warm=()
  for i in $(seq 1 "$warm_runs"); do
    start=$(now_ns)
    if ! nix build --dry-run --no-link "$flake#$build_attr" >/dev/null 2>"$stderr_file"; then
      echo "warm run $i failed:" >&2
      cat "$stderr_file" >&2
      exit 1
    fi
    end=$(now_ns)
    seconds=$(elapsed "$start" "$end")
    warm+=("$seconds")
    printf 'run %d: %ss\n' "$i" "$seconds" >>"$out/timing-warm.txt"
    echo "[$target] warm run $i: ${seconds}s"
  done

  # Cold runs: eval cache disabled, mirroring the first eval after an edit.  : >"$out/timing-cold.txt"
  local cold=()
  for i in $(seq 1 "$cold_runs"); do
    start=$(now_ns)
    if ! nix eval --raw --option eval-cache false "$flake#$attr" >/dev/null 2>"$stderr_file"; then
      echo "cold run $i failed:" >&2
      cat "$stderr_file" >&2
      exit 1
    fi
    end=$(now_ns)
    seconds=$(elapsed "$start" "$end")
    cold+=("$seconds")
    printf 'run %d: %ss\n' "$i" "$seconds" >>"$out/timing-cold.txt"
    echo "[$target] cold run $i: ${seconds}s"
  done

  # Instrumented run: evaluator stats, per-call-site counts, sampling
  # profiler and IFD tracing. Timing from this run is not comparable.
  echo "[$target] instrumented run (stats + flamegraph)..."
  start=$(now_ns)
  if ! NIX_SHOW_STATS=1 NIX_COUNT_CALLS=1 NIX_SHOW_STATS_PATH="$PWD/$out/stats.json" \
    nix eval --raw \
    --option eval-cache false \
    --option eval-profiler flamegraph \
    --option eval-profile-file "$PWD/$out/nix.profile" \
    --option eval-profiler-frequency "$frequency" \
    --option trace-import-from-derivation true \
    "$flake#$attr" >/dev/null 2>"$out/eval.log"; then
    echo "instrumented run failed:" >&2
    cat "$out/eval.log" >&2
    exit 1
  fi
  end=$(now_ns)
  local inst
  inst=$(elapsed "$start" "$end")
  echo "[$target] instrumented run: ${inst}s"

  # Evaluator statistics summary.
  if [ -f "$out/stats.json" ]; then
    jq '
      {
        cpuTime,
        time,
        gc,
        nrExprs,
        nrFunctionCalls,
        nrPrimOpCalls,
        nrThunks,
        nrLookups,
        nrAvoided,
        envs,
        values,
        sets,
        list,
        symbols,
        callSites: ((.functions // []) | sort_by(-.count) | .[0:40])
      }' "$out/stats.json" >"$out/stats-summary.json"
    jq '{cpuTime, nrFunctionCalls, nrThunks, nrExprs, gc}' "$out/stats.json" >"$out/stats-summary.txt"
  fi

  # IFD report.
  if grep -qi 'import from derivation' "$out/eval.log" 2>/dev/null; then
    grep -i 'import from derivation' "$out/eval.log" >"$out/ifd.txt" || true
    echo "[$target] IFD detected: $(wc -l <"$out/ifd.txt") trace(s), see $out/ifd.txt"
  else
    rm -f "$out/ifd.txt"
  fi

  # Flamegraph. Normalise frames: strip the «flake» store prefix so paths
  # stay readable in the SVG and top-leaves report.
  local samples=0 fg
  if [ -s "$out/nix.profile" ]; then
    sed 's/«[^»]*»\///g' "$out/nix.profile" >"$out/nix.folded"
    samples=$(awk '{ sum += $NF } END { print sum + 0 }' "$out/nix.folded")
    if fg=$(find_flamegraph); then
      "$fg" --title "$target (cold eval, $inst s)" "$out/nix.folded" >"$out/flamegraph.svg"
    else
      echo "[$target] flamegraph.pl unavailable, keeping folded profile only" >&2
    fi
    awk '
      {
        count = $NF
        $NF = ""
        n = split($0, frames, ";")
        leaf = frames[n]
        gsub(/^ +| +$/, "", leaf)
        self[leaf] += count
        total += count
      }
      END {
        for (k in self) printf "%6.1f%%  %8d  %s\n", 100 * self[k] / total, self[k], k
      }' "$out/nix.folded" | sort -rn | sed -n '1,30p' >"$out/top-leaves.txt"
    # Inclusive time: attribute each sample to every distinct frame in its stack.
    awk '
      {
        count = $NF
        $NF = ""
        n = split($0, frames, ";")
        delete seen
        for (i = 1; i <= n; i++) {
          f = frames[i]
          gsub(/^ +| +$/, "", f)
          if (f != "" && !(f in seen)) {
            seen[f] = 1
            incl[f] += count
          }
        }
        total += count
      }
      END {
        for (k in incl) printf "%6.1f%%  %8d  %s\n", 100 * incl[k] / total, incl[k], k
      }' "$out/nix.folded" | sort -rn | sed -n '1,40p' >"$out/top-inclusive.txt"
  else
    echo "[$target] no profiler samples (eval too short?)" >&2
  fi

  rm -f "$stderr_file"

  # Append to history for A/B comparisons.
  local history="profile/history.tsv"
  if [ ! -f "$history" ]; then
    printf 'timestamp\ttarget\tgit\twarm\tcold\tinstrumented\tcpuTime\tnrFunctionCalls\tnrThunks\tsamples\n' >"$history"
  fi
  local warm_csv cold_csv cpu calls thunks
  warm_csv=$(IFS=,; echo "${warm[*]:-}")
  cold_csv=$(IFS=,; echo "${cold[*]:-}")
  cpu=$(jq -r '.cpuTime // empty' "$out/stats.json" 2>/dev/null || echo "")
  calls=$(jq -r '.nrFunctionCalls // empty' "$out/stats.json" 2>/dev/null || echo "")
  thunks=$(jq -r '.nrThunks // empty' "$out/stats.json" 2>/dev/null || echo "")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(date -Is)" "$target" "$(git rev-parse --short HEAD 2>/dev/null || echo n/a)" \
    "$warm_csv" "$cold_csv" "$inst" "$cpu" "$calls" "$thunks" "$samples" >>"$history"

  echo
  echo "== $target =="
  echo "warm (eval-cache):  ${warm[*]:-n/a}s"
  echo "cold (no cache):    ${cold[*]:-n/a}s"
  echo "instrumented:       ${inst}s  (stats+profiler overhead, do not compare)"
  if [ -f "$out/stats.json" ]; then
    echo "cpu time:           $(jq -r '.cpuTime' "$out/stats.json")s"
    echo "function calls:     $(jq -r '.nrFunctionCalls' "$out/stats.json")"
    echo "thunks:             $(jq -r '.nrThunks' "$out/stats.json")"
  fi
  echo "profiler samples:   $samples"
  if [ -f "$out/ifd.txt" ]; then
    echo "IFD traces:         $(wc -l <"$out/ifd.txt") (see $out/ifd.txt)"
  fi
  echo "artifacts:          $out/"
  if [ -f "$out/flamegraph.svg" ]; then
    echo "flamegraph:         $out/flamegraph.svg"
  fi
  if [ -f "$out/top-leaves.txt" ]; then
    echo "top self-time frames:"
    sed 's/^/  /' "$out/top-leaves.txt"
  fi
}

if [ "$all" -eq 1 ]; then
  targets=$(
    {
      list_targets nixosConfigurations nixos
      list_targets darwinConfigurations darwin
      list_targets homeConfigurations home
    } | tr '\n' ' '
  )
  echo "profiling: $targets"
  for t in $targets; do
    profile_one "$t"
    echo
  done
  exit 0
fi

[ -n "$target" ] || usage
profile_one "$target"
