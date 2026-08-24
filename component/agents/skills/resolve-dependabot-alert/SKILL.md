---
name: resolve-dependabot-alert
description: Fix a Dependabot security alert for an npm/pnpm workspace. Load when given a Dependabot alert URL or number, or asked to fix a dependency vulnerability.
---

## Orient

Fetch the alert to get the package name, vulnerable range, and first patched version.

Prefer the GitHub MCP Dependabot tool (`github_get_dependabot_alert`) when it is
available and authenticated. If the tool is unavailable or returns an auth error,
fall back to the `gh` CLI:

```
gh api repos/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/dependabot/alerts/<number>
```

If a Dependabot alert URL is given (e.g. `https://github.com/org/repo/security/dependabot/93`), extract the number from the URL.

The Dependabot tool may become available after the GitHub MCP configuration is
reloaded; retry it before falling back to `gh`.

Extract from the response:
- `dependency.package.ecosystem` — must be `npm`; exit if not
- `dependency.package.name` — the vulnerable package
- `security_vulnerability.vulnerable_version_range`
- `security_vulnerability.first_patched_version.identifier`

## Scan the lockfile

Check `pnpm-lock.yaml` for the package. Confirm a vulnerable version is present before making any change.

## Apply the fix

This workspace uses a **pnpm catalog** in `pnpm-workspace.yaml` as the single source of truth for shared dep versions.

**Case A — package is already in the catalog**: bump its version to `^<first_patched_version>`.

**Case B — package is not in the catalog**: add it as `<name>: '^<first_patched_version>'` under the existing security-fix entries. Add a comment referencing the alert number on the line above, matching the style of adjacent entries.

Then run:

```
pnpm install
```

## Verify

After install, grep `pnpm-lock.yaml` for the package name and confirm:
- No vulnerable version is present
- The resolved version is >= the first patched version
