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
