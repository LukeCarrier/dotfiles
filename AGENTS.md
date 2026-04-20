# AGENTS.md

This document provides context and navigation guidance for AI agents working with this repository.

---

## Repository Overview

This is a Nix-based dotfiles repository managing system configurations for macOS and NixOS, with support for Android via nix-on-droid. The repository uses:

- **Nix flakes** for reproducible builds
- **home-manager** for user-level configuration
- **nix-darwin** for macOS system configuration
- **sops-nix** for encrypted secrets management

---

## Directory Structure

### `/component/`

Contains modular Nix configurations for individual software packages and system components. Each subdirectory represents a self-contained configuration module.

**Naming convention:** Lowercase, hyphen-separated (e.g., `hyprland/`, `zed/`)

**Structure:** Each component typically contains:
- `<component>.nix` - Main NixOS/home-manager module
- `darwin.nix` - macOS-specific configuration (when applicable)
- `home.nix` - Home-manager specific configuration (when applicable)

**Notable components:**
- `opencode/` - AI assistant configuration (see [OpenCode](#opencode) section)
- `hyprland/` - Wayland compositor configuration
- `niri/` - Wayland compositor configuration
- `firefox/` - Browser configuration
- `ghostty/` - Terminal emulator configuration
- `zed/` - IDE configuration
- `vscode/` - VS Code configuration
- `helix/` - Editor configuration
- `hypridle/`, `hyprlock/`, `hyprpaper/` - Hyprland ecosystem tools

### `/platform/`

Platform-specific system configurations. Contains NixOS and macOS system-level configurations.

**Structure:**
- `nixos/` - NixOS system configurations
- `darwin/` - macOS system configurations
- `android/` - Android-specific configurations (via nix-on-droid)

Each platform directory contains:
- `common.nix` - Shared configuration across all instances of that platform
- `graphical.nix` - Graphical desktop environment settings (NixOS)
- Host-specific configurations in subdirectories (e.g., `luke-c0nstruct/`)

### `/package/`

Nix package definitions that aren't part of nixpkgs. Contains custom builds and overlays.

**Structure:**
- `default.nix` - Package set entry point
- Individual package directories with their own `default.nix`
- `legacy-packages.nix` - Legacy package definitions

**Notable packages:**
- `aws-cli-tools/` - AWS CLI utilities
- `bw-cli-tools/` - Bitwarden CLI utilities
- `github-cli-tools/` - GitHub CLI utilities
- `kubernetes-client-tools/` - Kubernetes client utilities
- `python-modules/` - Python package definitions (including PyObjC bindings)

### `/employer/`

Employer-specific configurations (currently `emed/`). Contains work-related tooling and configurations.

### `/system/`

System-specific NixOS configurations. Each subdirectory represents a specific machine.

**Structure:**
- `<hostname>/` - Machine-specific directory
- `user/` - User configurations for that machine
- `hardware-configuration.nix` - Auto-generated hardware profile
- `default.nix` - Machine entry point

### `/shell/`

Shell environment configuration and development shell definitions.

### `/lib/`

Shared Nix library functions and utilities.

### `/adrs/`

Architecture Decision Records following the [ADR log pattern](https://adr.github.io/).

**Structure:**
- `<YYYY-MM-DD>-<feature-slug>/` - ADR directory
  - `spec.md` - Specification document
  - `plan.md` - Technical plan
  - `tasks.md` - Implementation tasks
  - `retro.md` - Retrospective (optional)
- `README.md` - Index of all ADRs by status

**ADR workflow:**
1. `/adr.specify` - Create specification with measurable requirements
2. `/adr.plan` - Design architecture and implementation approach
3. `/adr.tasks` - Break down into implementable tasks
4. `/adr.implement` - Execute the plan
5. `/adr.reflect` - Capture learnings and improve process

See `component/opencode/commands/` for command templates.

### `/secrets/`

Encrypted secrets managed by SOPS. Contains sensitive configuration data.

**Files:**
- `personal.yaml` - Personal secrets
- `employer-emed.yaml` - Employer-specific secrets

**Management:**
- Edit with `sops <file>`
- Keys stored in `.sops/keys/`

---

## OpenCode Configuration

The repository includes an [OpenCode](https://opencode.ai/) AI assistant configuration in `component/opencode/`.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        OpenCode Agents                          │
├─────────────────────────────────────────────────────────────────┤
│  Primary Agents (standalone, independent execution)             │
│  • Adrian - ADR Architect (gemini-2.5-flash)                    │
│  • Edmund - Explorer (read-only)                                │
│  • Litterbox - Sandbox Executor (multi-model)                   │
│                                                                 │
│  Subagents (invoked by primary agents)                          │
│  • Scout - Security Analyst (claude-sonnet-4.5)                 │
│  • Quest - Quality Analyst (claude-sonnet-4.5)                  │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Roles

| Agent | Model | Mode | Permissions | Purpose |
|-------|-------|------|-------------|---------|
| **Adrian** | gemini-2.5-flash | primary | edit: adrs/* only | ADR planning cycle: spec → plan → tasks |
| **Scout** | claude-sonnet-4.5 | subagent | full | Security analysis, vulnerability identification |
| **Quest** | claude-sonnet-4.5 | subagent | full | Quality assurance, testing gaps |
| **Edmund** | read-only | primary | none | Codebase exploration, analysis |
| **Litterbox** | multi-model | primary | sandbox-only | Safe execution in isolated environments |

### Commands

| Command | Agent | Purpose |
|---------|-------|---------|
| `/adr.specify` | Adrian | Create ADR specification with requirements |
| `/adr.plan` | Adrian | Create technical plan based on spec |
| `/adr.tasks` | Adrian | Break plan into implementable tasks |
| `/adr.reflect` | Adrian | Capture learnings and improve process |
| `/adr.implement` | General | Execute tasks (owned by implementation agent) |

### Skills

Procedural knowledge modules:

- **direnv** - Environment variable handling guidance

### MCP Servers

Configured declaratively in `opencode.nix`:

- **emcee** - GitHub MCP server
- **github-mcp-server** - GitHub integration
- **terraform-mcp-server** - Terraform state management
- **mcp-remote** - Remote MCP server access

Secrets use `@PLACEHOLDER@` substitution → `config.sops.placeholder.<secret-name>`.

### Model Providers

- **Google** - Gemini 2.5 Flash/Pro, 3 Flash/Pro Preview
- **Kiro** - Claude Sonnet 4.5/4.6, Opus 4.5/4.6
- **Llama-Swap** - Qwen3 Coder 480B, GLM-4.7 Flash

---

## Development Workflow

### Building and Applying

**Makefile targets:**
```makefile
make host          # Apply NixOS configuration
make home          # Apply home-manager configuration
make host-darwin   # Apply macOS configuration
make host-android  # Apply nix-on-droid configuration
```

**Manual commands:**
```bash
# NixOS
sudo nixos-rebuild switch --flake .#<hostname>

# macOS
sudo nix run nix-darwin -- switch --flake .#<hostname>

# Home Manager
nix run home-manager -- switch --flake .#<user>@<hostname>
```

### Secrets Management

1. Add new secret to appropriate `secrets/*.yaml` file
2. Encrypt with SOPS: `sops <file>`
3. Reference in Nix config: `config.sops.placeholder.<secret-name>`
4. Apply configuration: `make host` or `make home`

### Adding New Components

1. Create directory in `component/<name>/`
2. Add `<name>.nix` with module definition
3. Reference in `system/<host>/default.nix` or `platform/darwin/common.nix`
4. Test with `make host` or `make home`

---

## Conventions and Patterns

### Nix Module Structure

```nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myModule.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable myModule";
  };

  config = lib.mkIf config.myModule.enable {
    home.packages = [ pkgs.myPackage ];
    # ... configuration
  };
}
```

### Collapsing Single-Value Attrsets

When an attribute set has exactly one value, collapse it using dotted key notation instead of a nested block. This is a standard Nix idiom equivalent to writing the full attrset, but more concise.

**Collapsed (preferred):**
```nix
home.file = {
  ".config/goose/adrs/recipes/housekeeping.sh".source = ./adrs/recipes/housekeeping.sh;
  ".config/goose/adrs/recipes/recipe.yaml".source = ./adrs/recipes/recipe.yaml;
};
```

**Equivalent verbose form (avoid):**
```nix
home.file = {
  ".config/goose/adrs/recipes/housekeeping.sh" = {
    source = ./adrs/recipes/housekeeping.sh;
  };
  ".config/goose/adrs/recipes/recipe.yaml" = {
    source = ./adrs/recipes/recipe.yaml;
  };
};
```

This applies to any attribute set with a single key — `home.file`, `services.*.extraConfig`, `environment.etc.*`, etc. When a set grows beyond one key, switch to the nested block form.

### Platform-Specific Conditionals

Components frequently need different behaviour on macOS (Darwin) versus Linux (NixOS). The repository uses several established patterns for this:

**`lib.mkIf` for conditional module attributes:**
```nix
home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgs.some-darwin-only-package ];
```

**`if` expressions for value selection:**
```nix
package = if stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
```

**Platform-conditional socket paths and service names:**
```nix
socketPath =
  if stdenv.isDarwin then
    "Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
  else
    ".bitwarden/ssh-agent.sock";
```

Use `stdenv.isDarwin` / `stdenv.isLinux` for boolean checks. Use `stdenv.hostPlatform.isDarwin` when the value is used in a conditional expression that selects between two concrete values. Prefer `lib.mkIf` when enabling or disabling entire attribute sets.

**`darwin.nix` files for macOS-only Homebrew installs:**
Components on macOS may include a `darwin.nix` file that runs in the `nix-darwin` context and installs Homebrew casks or MAS apps. These are referenced from the host's `platform/darwin/common.nix` or host-specific config.

**`home.nix` files for cross-platform home-manager modules:**
Components may include a `home.nix` file for home-manager options that apply on both macOS and Linux, keeping them separate from the main NixOS-specific module.

See `component/1password/`, `component/bitwarden/`, `component/ghostty/`, and `component/opencode/` for examples of these patterns in practice.

### Component File Structure

Components follow a consistent file layout depending on their platform requirements:

**Single-module components (most common):**
```
component/ghostty/ghostty.nix
```

**Components with macOS Homebrew installs:**
```
component/goose/
  goose.nix       # home-manager module (nixos + darwin)
  darwin.nix      # nix-darwin module (Homebrew casks only)
```

**Components with Linux-specific and home-manager modules:**
```
component/1password/
  1password.nix   # homebrew casks (darwin.nix in this case)
  home.nix        # home-manager module (cross-platform)
```

**Components with shared Nix logic:**
```
component/fish/
  default.nix     # shared configuration (used by nixos + darwin)
  fish.nix        # fish-specific module
```

The `default.nix` entry point is used when a component needs to share logic between NixOS and macOS contexts. Individual `<component>.nix` files are the default entry point for self-contained modules.

See `component/fish/`, `component/1password/`, and `component/bitwarden/` for examples.

### Nix Idioms

**`inherit (pkgs)` for common imports:**
When a component needs both `lib` and `stdenv` from `pkgs`, use `inherit` rather than listing them separately:
```nix
{ pkgs, ... }:
let
  inherit (pkgs) lib stdenv;
in
{
  settings = if stdenv.isDarwin then { } else { };
}
```

**`pkgs.lib.mkDefault` for SOPS file paths:**
When a SOPS secret's source file may differ between hosts but a sensible default exists, use `mkDefault` so host-level config can override it:
```nix
sopsFile = pkgs.lib.mkDefault ../../secrets/personal.yaml;
```

See `component/goose/goose.nix` and `component/opencode/opencode.nix` for examples.

**SOPS secret declarations use camelCase keys matching the YAML:**
```nix
sops = {
  secrets."goose-openai-api-key" = {
    sopsFile = ../../secrets/personal.yaml;
    format = "yaml";
    key = "goose/openai-api-key";
  };
};
```

The hyphenated secret name becomes the SOPS placeholder reference (e.g., `config.sops.placeholder.goose-openai-api-key`), while the `key` field maps to the nested path in the encrypted YAML.

### File Naming

- **Nix files**: Lowercase, hyphen-separated (`hyprland.nix`)
- **Shell scripts**: Lowercase, hyphen-separated, executable (`adr.housekeeping.sh`)
- **Documentation**: Lowercase, hyphen-separated (`adr.specify.md`)

### YAML Frontmatter

Documents use YAML frontmatter for metadata:

```yaml
---
status: draft | accepted | rejected | implemented | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: <author-name>
decision: accepted | rejected | pending
---
```

---

## Testing and Validation

### Local Development

```bash
# Check Nix syntax
nix-instantiate --parse <file>

# Evaluate configuration without applying
nix eval .#packages.<system>.<package-name>

# Build package without installing
nix build .#packages.<system>.<package-name>
```

### CI/CD

The repository uses GitHub Actions for automated testing. See `.github/workflows/` for workflows.

---

## Troubleshooting

### Common Issues

**Build failures due to flakes:**
```bash
# Clear flake cache
nix flake lock --update-input <input-name>
```

**Secret decryption failures:**
```bash
# Verify AGE key is in .sops/keys
cat .sops/keys

# Update keys for all secrets
sops updatekeys secrets/*
```

**Home Manager errors:**
```bash
# Check configuration syntax
nix eval .#homeConfigurations.<user>@<hostname>.activationScript

# Dry run
nix run home-manager -- dry-run --flake .#<user>@<hostname>
```

---

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [home-manager](https://nix-community.github.io/home-manager/)
- [nix-darwin](https://nix-darwin.readthedocs.io/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [OpenCode Documentation](https://opencode.ai/docs)

---

*Last updated: 2026-04-04*
