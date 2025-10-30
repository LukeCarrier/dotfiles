<!--
Sync Impact Report:
Version change: Initial → 1.0.0
Modified principles: N/A (initial creation)
Added sections:
  - Core Principles (5 principles)
  - Architecture Constraints
  - Quality Standards
  - Governance
Removed sections: N/A
Templates requiring updates:
  ✅ .specify/templates/plan-template.md - reviewed, aligned
  ✅ .specify/templates/spec-template.md - reviewed, aligned
  ✅ .specify/templates/tasks-template.md - reviewed, aligned
Follow-up TODOs: None
-->

# Dotfiles Constitution

## Core Principles

### I. Modularity & Composability

Components MUST be self-contained and independently usable modules. Each component:
- Lives in its own directory under `component/`
- Exposes a clear Nix module interface
- Declares all dependencies explicitly
- Can be enabled/disabled per-system without side effects
- MUST NOT assume presence of other components

**Rationale**: Enables selective feature adoption across different systems (NixOS, macOS, Android) while maintaining configuration consistency.

### II. Platform Abstraction

Platform-specific implementations MUST be isolated behind platform modules. Components:
- Provide platform-agnostic defaults in base `.nix` files
- Use platform-specific overrides (`darwin.nix`, `nixos.nix`, etc.) only when necessary
- MUST NOT contain platform conditionals within core logic
- Share configuration data across platforms where semantically equivalent

**Rationale**: Same component definitions work across NixOS, nix-darwin, and nix-on-droid with minimal platform-specific code.

### III. Declarative Configuration

All system and application configuration MUST be expressed declaratively in Nix. Configuration:
- MUST use Nix expressions for all settings
- MUST NOT rely on imperative setup scripts or manual post-install steps
- MUST be reproducible: same flake input → identical system state
- Version-controls all configuration state

**Rationale**: Enables atomic rollbacks, reproducible builds, and configuration-as-code workflows.

### IV. Secret Management

Secrets MUST be managed through sops-nix with AGE encryption. Secret handling:
- MUST NOT commit plaintext secrets to version control
- MUST use `.sops/keys` for AGE private keys (gitignored)
- MUST edit encrypted files with `sops $path` command
- MUST declare secret paths in system configurations
- Secrets deployed atomically with system activation

**Rationale**: Secure credential management compatible with declarative Nix workflow and multi-machine deployments.

### V. Component Testing & Validation

Component changes MUST be tested on target platforms before merge. Testing:
- MUST verify `nix flake check` passes
- MUST validate on at least one representative system (darwin/nixos)
- SHOULD test cross-platform components on multiple platforms
- MUST ensure clean activation (no errors/warnings)

**Rationale**: Prevents breakage across heterogeneous fleet of systems with different hardware and platform constraints.

## Architecture Constraints

### Directory Structure

The repository MUST maintain this canonical structure:

```
component/       # Modular feature components
├─ <name>/
│  ├─ <name>.nix        # Base component module
│  ├─ darwin.nix        # macOS-specific (optional)
│  ├─ nixos.nix         # NixOS-specific (optional)
│  └─ home.nix          # home-manager config (optional)

system/          # System-specific configurations
├─ <hostname>/
│  ├─ default.nix       # System configuration
│  ├─ hardware-configuration.nix  # NixOS hardware (optional)
│  └─ user/<username>/default.nix  # User home-manager config

platform/        # Platform base modules (nixos/darwin/android)
hw/              # Hardware-specific modules (framework-13-amd, macbook)
package/         # Custom Nix package definitions
employer/        # Employer-specific configurations (optional)
.sops/           # Secret keys (gitignored)
flake.nix        # Flake entrypoint
```

**Constraint**: New components MUST NOT introduce top-level directories. Custom packages belong in `package/`, not `pkgs/` or `packages/`.

### Nix Flake Requirements

The `flake.nix` MUST:
- Pin all inputs with locked revisions
- Define outputs for all systems: `darwinConfigurations`, `nixosConfigurations`, `homeConfigurations`
- Use `flake-utils` or equivalent for cross-platform builds
- Keep custom packages in `packages.<system>` output

### Component Naming

Component directory names MUST:
- Use lowercase with hyphens (e.g., `kubernetes-client`, not `k8s` or `KubernetesClient`)
- Match primary tool/application name when possible
- Use descriptive names for bundles (e.g., `shell-essential`)

## Quality Standards

### Documentation

Components SHOULD include:
- Brief comment at top of `.nix` file explaining purpose
- Configuration examples for non-obvious options
- Platform compatibility notes if not universal

System READMEs MUST document:
- Setup prerequisites (Homebrew, Rosetta, etc.)
- Initial installation commands
- Secret management workflow

### Code Style

Nix code MUST:
- Use 2-space indentation
- Format with `nixpkgs-fmt` or `alejandra`
- Prefer `lib.mkIf` over conditional logic
- Use `lib.mkEnableOption` for component toggles

### Breaking Changes

Changes that remove/rename component options MUST:
- Increment constitution version (MAJOR)
- Document migration path in commit message
- Provide deprecation warnings where feasible

## Governance

### Amendment Procedure

Constitution amendments require:
1. Propose change with clear rationale
2. Validate against existing components (no breaking changes without migration plan)
3. Update dependent templates (plan/spec/tasks templates)
4. Increment version according to semantic versioning
5. Document in Sync Impact Report (HTML comment at file top)

### Versioning Policy

- **MAJOR**: Remove/rename core principles, change directory structure, break component interface contracts
- **MINOR**: Add new principles, expand constraints, new mandatory documentation sections
- **PATCH**: Clarify wording, fix typos, non-semantic refinements

### Compliance Review

All PRs MUST:
- Verify compliance with current constitution version
- Justify complexity if introducing new top-level directories or platform-specific workarounds
- Pass `nix flake check` and manual activation test on representative system
- Update constitution if patterns evolve beyond current rules (amendment procedure applies)

**Version**: 1.0.0 | **Ratified**: 2025-10-30 | **Last Amended**: 2025-10-30
