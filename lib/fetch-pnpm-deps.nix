# Wrapper around nixpkgs' `fetchPnpmDeps` that keeps the fixed-output hash
# platform-independent.
#
# pnpm 12 has a macOS-only `DirCloneCache` whose capability probe creates
# `<store>/links` in the pnpm store. `fetchPnpmDeps` archives the whole store,
# so the extra empty directory yields a different hash on Darwin than on Linux.
# Forcing hardlink imports skips the clone cache entirely, leaving the store
# contents identical on every platform.
#
# Remove once nixpkgs' `fetchPnpmDeps` cleans up `<store>/links` itself.
{ pkgs }:
args:
pkgs.fetchPnpmDeps (
  args
  // {
    prePnpmInstall = ''
      pnpm config set package-import-method hardlink
      ${args.prePnpmInstall or ""}
    '';
  }
)
