# Implementation Plan: DevShell Tool Version Display

**Branch**: `001-devshell-tool-versions` | **Date**: 2025-10-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-devshell-tool-versions/spec.md`

## Summary

Systematically display versions of all tools installed in Nix devShells by enhancing the shellHook in each devShell definition. Currently, some devShells (goDev, nodeDev, kotlinDev, pythonDev, rustDev) have manual version printing, while others (default) do not. This feature will standardize and automate version detection across all devShells, ensuring consistent formatting and graceful error handling for tools that don't support standard version flags.

## Technical Context

**Language/Version**: Nix 2.x (for devShell definitions), Bash/POSIX shell (for shellHook scripts)  
**Primary Dependencies**: Nix flakes, mkShell, existing devShells in `shell/default.nix`  
**Storage**: N/A (ephemeral console output only)  
**Testing**: Manual testing via `nix develop .#<shell-name>`, verification across all defined devShells  
**Target Platform**: Cross-platform (Linux, macOS, any platform supporting Nix)
**Project Type**: Infrastructure enhancement (modifying existing shell definitions)  
**Performance Goals**: Version detection completes in <1 second for typical devShells (≤10 tools)  
**Constraints**: Must not block shell initialization; must handle missing/failing tools gracefully; must work with tools that use different version flags (--version, -v, -V, version subcommand)  
**Scale/Scope**: 6 devShells currently defined in `shell/default.nix` (default, goDev, nodeDev, kotlinDev, pythonDev, rustDev)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✓ Component Modularity (Principle I)

**Status**: PASS  
**Assessment**: This enhancement modifies existing devShell definitions in `shell/default.nix`. No new components required. Changes are self-contained within the shell definitions file.

### ✓ Platform Abstraction (Principle II)

**Status**: PASS  
**Assessment**: Shell scripting (Bash/POSIX) for version detection is platform-agnostic. Implementation works identically on NixOS, macOS (nix-darwin), and other Unix-like platforms. No platform-specific logic required.

### ✓ Declarative Configuration (Principle III)

**Status**: PASS  
**Assessment**: shellHook scripts are declaratively defined in Nix expressions. All version detection logic expressed as Nix strings within mkShell calls. No imperative scripts or manual setup.

### ✓ Secret Management (Principle IV)

**Status**: N/A  
**Assessment**: Feature does not handle secrets.

### ✓ Directory Structure Constraint

**Status**: PASS  
**Assessment**: Changes confined to existing `shell/default.nix` file. No new directories or files introduced beyond documentation in `specs/`.

### ✓ Nix Flake Requirements

**Status**: PASS  
**Assessment**: No changes to flake.nix required. devShells output already properly defined via `import ./shell`.

### ✓ Component Naming

**Status**: N/A  
**Assessment**: No new components being named.

## Project Structure

### Documentation (this feature)

```text
specs/001-devshell-tool-versions/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output: version detection strategies
├── data-model.md        # Phase 1 output: shellHook data structures
├── quickstart.md        # Phase 1 output: usage examples
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
shell/
└── default.nix          # Existing file to be modified
                         # Will enhance shellHook in all devShells

# No contracts/ directory needed - this is infrastructure code
# with well-defined Nix API (mkShell + shellHook)
```

**Structure Decision**: Single file modification. All implementation changes occur in the existing `shell/default.nix` file. Each devShell's shellHook will be enhanced with consistent version detection logic. No new helper files needed—logic will be inline or use Nix's `lib` utilities for string manipulation.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected. All constitution requirements satisfied by design.