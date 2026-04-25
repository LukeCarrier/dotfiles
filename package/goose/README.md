# Goose Desktop Build Package

## Overview

This directory contains Nix derivations for building all three Goose components:

| Package | Source | Description |
|---------|--------|-------------|
| `goose-cli` | [`goose.nix`](./goose.nix) | The CLI binary (`goose`) — full workspace build |
| `goose-server` | [`server.nix`](./server.nix) | The server binary (`goosed`) — server-only build |
| `goose-desktop` | [`desktop.nix`](./desktop.nix) | The Electron desktop app — bundles CLI + server |

## Build Strategy

### Independent Binaries for Faster Recovery

The desktop package depends on **two independently buildable Rust binaries**:

- **`goose-server`** (`server.nix`) — builds only the `goosed` server binary using `cargoBuildFlags = ["--bin" "goosed"]`. This skips the CLI (`goose`), the shared library crate, and all tests. A single-server rebuild is significantly faster than rebuilding the entire workspace.
- **`goose-cli`** (`goose.nix`, existing) — the full CLI build, reused from the existing package definition.

The desktop Electron app **copies these pre-built binaries** into its resources directory at install time rather than rebuilding them. This means:

- A broken desktop build only requires rebuilding the Electron frontend (Node.js/pnpm), not the entire Rust workspace.
- A broken server build only requires rebuilding `goosed`, not the CLI.
- Both binaries can be tested and validated independently.

### Build Flow

```
server.nix ────► goosed binary ─┐
                                ├──► desktop.nix ────► $out/bin/goose-desktop
goose.nix ─────► goose binary ──┘
```

1. **`goose-server`** builds `goosed` from the Rust source (server crate only).
2. **`goose-cli`** builds the CLI from the Rust source (full workspace).
3. **`goose-desktop`** installs Node.js dependencies, compiles i18n messages, generates the TypeScript API client from the OpenAPI spec, and packages the Electron app using `electron-forge package` (not `make` — we skip DEB/RPM/Flatpak since Nix is the packaging system).
4. At install time, `goose-desktop` copies the pre-built `goosed` and `goose` binaries into `$out/app/resources/bin/` and creates the `$out/bin/goose-desktop` wrapper.

## Platform Binary Helpers

The directory [`src-bin/`](./src-bin/) contains runtime helper scripts bundled with the Electron app for MCP server support:

- **`node` / `npx`** — Wrapper scripts that download and manage Hermit + Node.js at runtime. They set up a local Hermit environment in `~/.config/goose/mcp-hermit/` and install Node.js on first use.
- **`jbang`** — Wrapper for running Java-based MCP servers via JBang.
- **`uvx`** — Wrapper for running Python MCP servers via uv.
- **`node-setup-common.sh`** — Shared setup logic used by `node` and `npx` wrappers. These scripts handle downloading Hermit, initializing the environment, and installing Node.js on demand.

These scripts are **runtime dependencies**, not build dependencies. Electron Forge copies them into the app bundle via the `extraResource` configuration in `forge.config.ts`.

## How the Desktop Finds `goosed`

The Electron app searches for the `goosed` binary at these paths (in order):

1. `$GOOSED_BINARY` environment variable (set by the wrapper script in `$out/bin/goose-desktop`)
2. Packaged: `{resourcesPath}/bin/goosed` or `{resourcesPath}/goosed`
3. Development: `src/bin/goosed`, `../target/release/goosed`, or `../target/debug/goosed`

The wrapper script sets `$GOOSED_BINARY` to `${goosed}/bin/goosed` to avoid runtime path discovery in the Nix store.

## Dependencies

### Electron App Dependencies (Linux)

- **GTK3 ecosystem**: `glib`, `gtk3`, `atk`, `cairo`, `pango`, `gdk-pixbuf`, `at-spi2-atk`, `at-spi2-core`
- **Security**: `nss`, `nspr`, `libsecret`
- **Networking**: `dbus`, `cups`, `libdrm`, `libxkbcommon`
- **X11**: `xorg.libX11`, `xorg.libXcomposite`, `xorg.libXdamage`, `xorg.libXext`, `xorg.libXfixes`, `xorg.libXrandr`, `xorg.libXrender`, `xorg.libXtst`
- **Graphics**: `mesa`
- **System**: `alsa-lib`, `pam`, `libudev`
- **Build tooling**: `pnpm` (from `nodePackages`), `makeBinaryWrapper`

### Rust Dependencies

Inherited from the main Goose build in [`goose.nix`](./goose.nix):
- `openssl`, `cmake`, `protobuf`

## Version Management

All components share version **`1.32.0`**, sourced from the `v1.32.0` Git tag. When updating the version:

1. Update the `version` string in `server.nix` and `desktop.nix`.
2. Update the `tag` and `hash` in `fetchFromGitHub` to match the new tag.
3. Update the Cargo hash in `server.nix` if the dependency tree changed.
4. The existing `goose.nix` should already have matching version/hash for the CLI.

## Notes & TODO

- **[ ] Validate `goosed` runtime path**: The Electron app looks for `goosed` at `resources/bin/goosed`. This must be validated during manual testing — if the path discovery doesn't work as expected, the wrapper script may need adjustment.
- **[ ] `dontStrip = true`**: Stripping is disabled because Electron apps on Nix often break when stripped. This can be revisited if size is a concern.
- **pnpm**: Uses `nodePackages.pnpm` (corepack-managed). The Electron build requires Node 24.10+ and pnpm 10.30+.
- **Platform binary helpers**: These scripts download Hermit at runtime and manage Node.js for MCP servers. They are runtime-only; no build-time Hermit is needed.
- **`electron-forge make`**: Intentionally not used. This produces DEB/RPM/Flatpak distro packages — we skip these since Nix is the packaging system. `electron-forge package` produces the unpackaged Electron app directory, which is what we wrap.
