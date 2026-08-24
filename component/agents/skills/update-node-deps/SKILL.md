---
name: update-node-deps
description: Update npm/yarn/pnpm/bun dependencies — bump a specific package, apply a version constraint, or update the lockfile. Load when asked to upgrade a package, resolve a version conflict, update a lockfile, or apply a version override/resolution.
---

## Detect the package manager

Check for the lockfile that is present:

| Lockfile | Package manager |
|---|---|
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` (contains `__metadata:`) | Yarn 4 (Berry) |
| `yarn.lock` (no `__metadata:`) | Yarn 1 (Classic) |
| `package-lock.json` | npm |
| `bun.lockb` / `bun.lock` | Bun |

If `packageManager` is set in `package.json`, that is authoritative.

## Find where the version is declared

Before editing anything, locate the authoritative declaration:

1. **pnpm catalog** — `pnpm-workspace.yaml` `catalog:` block. This is the single source of truth for any dep listed there; do not also edit individual `package.json` files for cataloged packages.
2. **`package.json` `overrides` / `resolutions`** — a forced transitive pin. Present in root `package.json` (`overrides` for npm/pnpm, `resolutions` for Yarn).
3. **`pnpm-workspace.yaml` `overrides:`** — pnpm's workspace-level transitive pin; takes priority over `package.json` overrides.
4. **Individual `package.json`** — the dep's owning workspace.

Edit only the authoritative location.

## Apply the bump

### pnpm (catalog)

Edit the `catalog:` block in `pnpm-workspace.yaml`, then:

```sh
NODE_OPTIONS= pnpm install
```

> Use `NODE_OPTIONS=` if the workspace sets `--import <loader>` in `NODE_OPTIONS` via direnv — a fresh install with no `node_modules` will fail otherwise (the loader binary doesn't exist yet).

If `pnpm install` fails with a supply-chain policy error (`trustPolicy`, `minimumReleaseAge`, `blockExoticSubdeps`), read the error message: it names the offending package and version. Either:
- Pin a non-exotic, older-but-still-patched version that satisfies the policy.
- If the version is genuinely trustworthy, check whether a `trustPolicyExclude` entry is warranted and discuss with the user before adding one.

If `pnpm install` fails with `ERR_PNPM_TRUST_DOWNGRADE … Missing time for version X`:
- The lockfile's cached metadata is stale for that package.
- Run `pnpm clean --lockfile` then `NODE_OPTIONS= pnpm install` to rebuild from a fresh resolution.

### pnpm (no catalog)

Edit the relevant `package.json`, then `NODE_OPTIONS= pnpm install`.

### pnpm (transitive override)

Add or edit the `overrides:` block in `pnpm-workspace.yaml`:

```yaml
overrides:
  # Scoped: only when pulled by parent
  'parent-pkg>vulnerable-pkg': '^2.0.0'
  # Global: all resolved instances
  vulnerable-pkg: '^2.0.0'
```

Then `NODE_OPTIONS= pnpm install`.

### npm

```sh
npm install <pkg>@<version>
# or for a transitive override, edit "overrides" in root package.json, then:
npm install
```

### Yarn 4 (Berry)

```sh
yarn add <pkg>@<version>
# transitive: edit "resolutions" in root package.json, then:
yarn install
```

### Yarn 1 (Classic)

```sh
yarn add <pkg>@<version>
# transitive: edit "resolutions" in root package.json, then:
yarn install
```

### Bun

```sh
bun add <pkg>@<version>
# transitive: edit "overrides" in root package.json (bun 1.1+), then:
bun install
```

## Verify

After install, confirm the updated version is present:

```sh
# pnpm
pnpm list <pkg> --depth Infinity | grep <pkg>

# npm
npm list <pkg>

# Yarn
yarn why <pkg>

# Bun
bun pm ls | grep <pkg>
```

Confirm:
- No instance of the old (vulnerable/unwanted) version remains.
- The resolved version satisfies the constraint you applied.

For monorepos with multiple workspaces, check that no workspace pins a conflicting version that re-introduces the old one.
