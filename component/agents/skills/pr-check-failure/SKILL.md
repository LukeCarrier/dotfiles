---
name: pr-check-failure
description: Diagnosing and fixing failing GitHub Actions CI checks and broken builds
---

## When to use me

When a PR's GitHub Actions checks are failing and you need to determine the cause and fix it.

## Diagnosis workflow

1. **Fetch and switch to the PR branch** — get the exact branch name from the PR's `head.ref` field (via `github_pull_request_read` with `get` method), then use the `fetch-remote` skill to fetch, then use the `switch-branch` skill to check out that ref.

2. **Get the job logs using local tools first**
   - The repo is checked out to the local filesystem at `/home/lukecarrier/Code/throwparty/agentkit`.
   - To get job logs from a failing CI run: use `github_get_job_logs` with `return_content=true` and provide the `job_id` or `run_id`. The job ID is typically visible in the run URL as the last path segment.
   - Read the tool output file that gets saved (the truncated content) to find the actual error.
   - The logs contain ANSI escape sequences but the error messages are still readable.

3. **Read relevant files from disk, not from GitHub API**
   - CI workflow files are under `.github/workflows/` — read them directly from disk with the `Read` tool.
   - Composite actions are under `.github/actions/`.
   - The goreleaser config is `.goreleaser.yaml` at repo root.
   - The Nix flake is `nix/flake.nix`.
   - Source code is under `crates/`.
   - Do NOT use `github_get_file_contents` for files in this repo — they're available locally.

4. **Check if the failure is transient or real**
   - If the failure is `dorny/paths-filter` with a GitHub API 5xx error → transient, re-run the workflow.
   - If the failure mentions Nix hash mismatch → real, needs a hash update.
   - If the failure is a Nix daemon connection error → likely transient, re-run.

5. **For transient failures**: re-run via `github_actions_run_trigger` with `method=rerun_workflow_run` and the `run_id` from the run URL.

6. **For Nix hash mismatches**: the error output shows `got: sha256-<hash>` which is the correct hash. Extract it and update `cargoHash` in `nix/flake.nix`.

7. **For other failures**: inspect the full job log for the actual error message. Trace the call chain from the workflow file to understand the build steps.

### How to trace a build failure

1. Identify the failing job name from the run URL or job log.
2. Find the workflow file that defines that job (under `.github/workflows/`). Read it locally.
3. For release/snapshot builds, the job runs `goreleaser release --clean`. Read `.goreleaser.yaml` to see the targets and builder config.
4. For macOS cross-compilation, trace the env vars: `prepare-macos-sdk.sh` sets `SDKROOT`, `MACOSX_DEPLOYMENT_TARGET`, and `ZIG_SYSTEM_LIB_DIR`. The workflow passes these to the goreleaser Release step.
5. Look at the nix flake (`nix/flake.nix`) to see available tools (zig, cargo-zigbuild, etc.) and rust targets.

## Transient failures to ignore

- `dorny/paths-filter` → GitHub API 5xx, re-run
- Nix connection to daemon socket → re-run
- Any step that succeeds on re-run without code changes

## Rerunning workflows

Use `github_actions_run_trigger` — never `gh` CLI. Available methods:

- `rerun_workflow_run` — rerun the entire workflow run
- `rerun_failed_jobs` — rerun only failed jobs
- `cancel_workflow_run` — cancel a run stuck or in progress

All require `owner`, `repo`, and `run_id` from the run URL.
