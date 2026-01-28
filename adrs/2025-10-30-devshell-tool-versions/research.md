# Research: DevShell Tool Version Detection

**Feature**: 001-devshell-tool-versions  
**Date**: 2025-10-30  
**Status**: Complete

## Overview

This document consolidates research findings for implementing automated version detection across all Nix devShells. The approach leverages Nix's build system to cache version information, eliminating runtime overhead and complexity.

## Current State Analysis

### Existing Implementation Patterns

From `shell/default.nix`, current version detection approaches:

1. **goDev**: Mixed patterns with parsing
   - `dlv version | awk '/Version/{print $2}'` - parsing structured output
   - `go version` - direct output
   - `golangci-lint --version` - standard flag
   - `make --version | head -n 1` - first line extraction

2. **nodeDev**: Consistent flag usage
   - `node --version`, `pnpm --version`, `yarn --version`

3. **kotlinDev**: Subcommand pattern
   - `kotlin -version` (single dash)

4. **pythonDev**: Simple pattern
   - `python --version`

5. **rustDev**: Direct output
   - `cargo --version`, `rustc --version`

6. **default**: No version detection (9 tools)

### Observations

- **Inconsistency**: Different formatting and detection methods per shell
- **Runtime overhead**: Version commands run every time shell is entered
- **No standardization**: Output format varies
- **Missing coverage**: Default shell has no version detection

## Research Questions & Answers

### Q1: When should version detection occur?

**Decision**: Version detection occurs at **build time** when Nix constructs the devShell closure, not at runtime.

**Rationale**: 
- **Performance**: Zero runtime overhead. Versions cached in Nix store, displayed instantly
- **direnv context**: Users enter shells via direnv on `cd` - must be instantaneous
- **Simplicity**: No timeouts, no error handling, no fallbacks needed
- **Nix philosophy**: Leverage build system for reproducible, cacheable results

**Implementation**:
```nix
let
  toolVersions = pkgs.runCommand "tool-versions" {} ''
    ${pkgs.go}/bin/go version >> $out
    ${pkgs.nodejs}/bin/node --version >> $out
  '';
in
pkgs.mkShell {
  shellHook = ''
    cat ${toolVersions}
  '';
}
```

### Q2: How should version output be formatted?

**Decision**: Emit raw output from each tool's version command. No formatting, no parsing, no prefixes unless the tool doesn't include its own name.

**Examples**:
```
Python 3.12.1          (includes "Python", no prefix needed)
go version go1.21.5    (includes "go", no prefix needed)
cargo 1.75.0           (includes "cargo", no prefix needed)
v20.10.0               (no tool name, would need "node: " prefix)
1.1.1                  (no tool name, would need "age: " prefix)
```

**Rationale**: 
- Reduce noise - don't duplicate tool names
- Authentic output - users see what tools actually report
- Simple implementation - minimal string manipulation
- If tool output is self-describing, use it as-is
- Only add prefix when tool name is absent from output

### Q3: How to specify version commands for each tool?

**Decision**: Hardcode the exact version command for each tool. No helpers, no detection, no abstraction.

**Rationale**:
- No universal standard for version flags
- No clean way to auto-detect (parsing --help is unreliable)
- Explicit > complex
- Easy to maintain

**Implementation Pattern**:
```nix
toolVersions = pkgs.runCommand "tool-versions" {} ''
  ${pkgs.age}/bin/age --version >> $out
  ${pkgs.go}/bin/go version >> $out
  ${pkgs.kotlin}/bin/kotlin -version 2>&1 >> $out
  ${pkgs.nodejs}/bin/node --version >> $out
  ${pkgs.python314}/bin/python --version >> $out
'';
```

**Common Patterns**:
- Most tools: `--version`
- Go tools: `version` subcommand
- Kotlin: `-version` (single dash)
- Some output to stderr: use `2>&1`

### Q4: What about error handling?

**Decision**: No error handling. Build fails if version command fails.

**Rationale**: 
- Build-time execution catches errors during development, not at shell entry
- Failures are developer errors - fix the version command
- This is the first thing users see (direnv) - it must work correctly
- No silent failures or degraded behavior

## Tool-Specific Version Commands

Based on current devShell tools and testing:

| Tool | Binary Name | Version Command | Notes |
|------|-------------|-----------------|-------|
| age | age | `--version` | Outputs "age 1.1.1" |
| gnumake | make | `--version` | First line: "GNU Make 4.4.1" |
| nil | nil | `--version` | LSP for Nix |
| nixd | nixd | `--version` | Nix LSP |
| nix-index | nix-locate | `--version` | Binary differs from package |
| nixfmt-rfc-style | nixfmt | `--version` | Binary differs from package |
| ssh-to-age | ssh-to-age | `--version` | - |
| sops | sops | `--version` | - |
| treefmt | treefmt | `--version` | - |
| delve | dlv | `version` | Subcommand pattern |
| go | go | `version` | Outputs "go version go1.21.5..." |
| golangci-lint | golangci-lint | `--version` | - |
| gopls | gopls | `version` | Subcommand pattern |
| node | node | `--version` | Outputs "v20.10.0" (no tool name) |
| pnpm | pnpm | `--version` | Outputs version number only |
| yarn | yarn | `--version` | Outputs version number only |
| bun | bun | `--version` | Outputs version number only |
| typescript | tsc | `--version` | "Version 5.3.3" |
| kotlin | kotlin | `-version 2>&1` | Single dash, outputs to stderr |
| python | python | `--version` | "Python 3.12.1" |
| ruff | ruff | `--version` | - |
| cargo | cargo | `--version` | "cargo 1.75.0" |
| rustc | rustc | `--version` | "rustc 1.75.0" |
| lldb | lldb | `--version` | Multi-line output |
| rust-analyzer | rust-analyzer | `--version` | - |

## Implementation Strategy

### 1. Create version cache at build time

Use `pkgs.runCommand` to execute all version commands and store output in Nix store:

```nix
let
  toolVersions = pkgs.runCommand "devshell-versions" {} ''
    ${pkgs.go}/bin/go version >> $out
    echo "node: $(${pkgs.nodejs}/bin/node --version)" >> $out
    # ... etc
  '';
in
```

### 2. Display cached versions in shellHook

Simple `cat` of cached file:

```nix
pkgs.mkShell {
  shellHook = ''
    cat ${toolVersions}
  '';
  nativeBuildInputs = [ /* ... */ ];
}
```

### 3. Handle tool name prefix

- Tools that include name in output: use raw output
- Tools that don't: add `echo "toolname: $(command)"` wrapper

### 4. Apply to all devShells

Systematically add to each devShell in `shell/default.nix`:
- default
- goDev
- nodeDev
- kotlinDev
- pythonDev
- rustDev

## Benefits of Build-Time Approach

1. **Zero runtime cost**: `cat` is instant, no process spawning
2. **No timeouts needed**: Build fails if command hangs
3. **No error handling**: Build system handles failures
4. **Cached in Nix store**: Shared across all shells using same tool versions
5. **Reproducible**: Same inputs = same output
6. **Simple implementation**: No complex shell logic

## Critical Implementation Details

### Cache Invalidation

**Problem**: Nix aggressively caches `runCommand` derivations. Changes to the script content may not trigger rebuilds if the derivation is fetched from substituters (binary caches).

**Solution**: Force local builds by setting:
```nix
pkgs.runCommand "name" {
  preferLocalBuild = true;
  allowSubstitutes = false;
} ''
  # script
''
```

**Why this works**:
- `preferLocalBuild = true`: Tells Nix to build locally rather than fetch from cache
- `allowSubstitutes = false`: Prevents querying remote caches entirely
- Combined: Forces Nix to rebuild when script changes are detected

### Script Syntax

**Problem**: Bash redirection syntax must be correct for `writeShellScript`.

**Correct pattern**:
```bash
{
  command1
  command2
} >> "$out"
```

**Incorrect pattern** (syntax error):
```bash
>>"$out" {
  command1
  command2
}
```

### Output Commands: printf vs echo

**Preference**: Use `printf` over `echo` for formatted output.

**Rationale**:
- `printf` is POSIX-compliant and portable across shells
- `echo` behavior varies between shells (bash, dash, zsh) regarding escape sequences
- `printf` provides explicit format control

**Usage**:
```bash
# When adding prefix to tool output
printf "tool: %s\n" "$(command --version)"

# Direct output (no prefix needed)
command --version
```

### Using writeShellScript

**Pattern**:
```nix
let
  versionScript = pkgs.writeShellScript "version-script" ''
    {
      ${pkgs.tool}/bin/tool --version
    } >> "$out"
  '';
  toolVersions = pkgs.runCommand "versions" {
    preferLocalBuild = true;
    allowSubstitutes = false;
  } ''
    ${versionScript}
  '';
in
```

**Benefits**:
- Script becomes a store path (dependency)
- Changes to script create new store path
- runCommand sees new input, triggers rebuild
- Combined with `preferLocalBuild`, ensures cache invalidation

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Build time increase | Low | Version commands are fast (<100ms each) |
| Wrong version command | Low | Build fails, fix during development |
| Tool output changes | Low | Update version command as needed |
| Cache not invalidating | High | Use preferLocalBuild + allowSubstitutes flags |

## Conclusion

Build-time version caching is the optimal approach:
- Leverages Nix's strengths (build system, caching)
- Zero runtime overhead (critical for direnv)
- Eliminates complexity (no timeouts, error handling, fallbacks)
- Simple implementation (hardcoded version commands)

**Next Steps**: Proceed to Phase 1 (data-model.md and quickstart.md generation).
