---
name: pr-check-failure
description: Diagnose and fix failing GitHub Actions CI checks. Load when a PR's checks are red, a workflow run failed, or a build broke in CI.
---

## When to use me

When a PR's GitHub Actions checks are failing and you need to find the cause and fix it.

## Orient first

Discover the specifics — never assume paths, branch names, or stack:

- **Branch**: read the PR's `head.ref` (via `github_pull_request_read`). Fetch and check it out.
- **Local checkout**: the repo is on disk in the current workspace. Read workflow and source files from disk, not through the GitHub API — the API is slower and can serve a different ref than you have checked out.
- **Stack**: infer from the repo (workflow files, lockfiles, `flake.nix`, `package.json`, etc.). Don't presume a language or build tool.

## Get the logs

Fetch failing-job logs with `github_get_job_logs` (`return_content=true`), passing the `job_id` or `run_id` — the run ID is the last path segment of the run URL. Read the saved tool-output file to find the error. Logs carry ANSI escapes but the messages remain readable.

## Triage: transient or real

Classify before fixing — re-running a real failure wastes minutes; hand-patching a transient one wastes effort.

**Transient** — re-run, don't patch:
- Network/registry timeouts, 5xx from an upstream API, runner or daemon connection drops.
- A step that succeeds on re-run with no code change.

**Real** — needs a code/config fix:
- Compile/type/lint/test failures.
- Dependency-hash or lockfile mismatches (the error usually prints the expected value — extract and apply it).
- Anything that reproduces on re-run.

## Rerun workflows

Use `github_actions_run_trigger` (not the `gh` CLI). Methods, all requiring `owner`, `repo`, `run_id`:

- `rerun_workflow_run` — the whole run
- `rerun_failed_jobs` — only failed jobs
- `cancel_workflow_run` — a stuck run

## Trace a real build failure

1. Identify the failing job name from the run URL or log.
2. Find the workflow defining it under `.github/workflows/`; read it locally. Follow any composite actions under `.github/actions/`.
3. Follow the failing step to the command it runs, then to that command's config (build manifest, lockfile, task runner).
4. Trace env vars the step depends on back to where they're set — a missing or wrong env var is a common root cause.
5. Reproduce locally where feasible: running the same command on your checkout closes the loop faster than pushing and waiting for CI.

## Completion criterion

The originating check passes on a fresh run — not merely "the error message changed". For a real fix, confirm the same command succeeds locally (or, if CI-only, that the re-run goes green).
