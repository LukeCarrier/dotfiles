---
name: nix
description: Reading pinned Nix source and verifying configs in this repo. Load when you must consult the nixpkgs, home-manager, or flake input module/package source that the lock file actually pins, when reading what a home-manager option serializes to, or when checking that a flake attribute evaluates.
---

## Anti-patterns

- Do NOT run `find` against `/nix/store` — it is enormous and will time out or be rejected.
  Instead, resolve the store path for a specific input via `nix eval --impure --raw --expr` and read or grep files under that path directly.

## Read the pinned source, not the web

flake.lock pins every input to a revision. GitHub and project docs show a different, newer tree; trusting them means describing modules that were never in the build. To read the source the config actually uses, resolve the input's store path:

```bash
nix eval --impure --raw --expr '(builtins.getFlake "/home/lukecarrier/Code/LukeCarrier/dotfiles").inputs.<input>.outPath'
```

`--impure` is required — `getFlake` on a git tree refuses without it. The result is a store path (e.g. `/nix/store/<hash>-source`); read or grep files under it directly. Usable inputs: `nixpkgs-unstable`, `home-manager`, `ashell`, `niri`, etc.

The lock file (`flake.lock`) contains the `narHash` and `rev` for every input. The store path hash is derived from these — if the store path is not yet known, resolving via `nix eval` as above is the right approach rather than guessing hashes.

Cross-check the resolved rev against the lock with `nix flake metadata --json | jq -r '.locks.nodes["<input>"].locked.rev'`.

## Searching within a resolved store path

Once you have a store path, use `grep -rn` scoped to that path — never to `/nix/store` as a whole:

```bash
src=$(nix eval --impure --raw --expr '(builtins.getFlake "/home/lukecarrier/Code/LukeCarrier/dotfiles").inputs.<input>.outPath')
grep -rn "pattern" "$src/subdir/" 2>/dev/null | head -20
```

Scope the search to the most specific subdirectory you can (`lib/`, `pkgs/top-level/`, `modules/programs/`, etc.) to keep it fast.

## Where things live in a fetched source tree

- home-manager modules: `<src>/modules/programs/<name>.nix`
- nixpkgs packages: `<src>/pkgs/by-name/<first-letter>/<name>/package.nix`
- NixOS modules: `<src>/nixos/modules/...`

## Read the module for serialization semantics

The home-manager module (e.g. `programs.ashell`) is authoritative for options and serialization — not the project's docs. It declares the config format type, the filename, and any key migration. Example: `programs.ashell` uses `pkgs.formats.toml`, writes `ashell/config.toml` for ashell >= 0.5.0, and remaps `camelCase` keys to `snake_case` via `lib.hm.deprecations.remapAttrsRecursive` — so config written in Nix appears snake-cased in the generated file.

## Verify a flake attribute evaluates

Use ad-hoc `--expr` against `builtins.getFlake` when a dotted attr path is ambiguous (dots in a fragment are parsed as nested attrs, not module options). Example:

```bash
nix eval --impure --raw --expr 'let f = builtins.getFlake "/home/lukecarrier/Code/LukeCarrier/dotfiles"; in builtins.toString (builtins.map (p: p.name or "") f.homeConfigurations."<user>@<host>".config.home.packages)'
```

Dry-run a build to confirm a change traverses without building the world:

```bash
nix build --dry-run '.#nixosConfigurations.<host>.config.system.build.toplevel'
```