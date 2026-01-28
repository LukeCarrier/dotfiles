# Data Model: DevShell Tool Version Detection

**Feature**: 001-devshell-tool-versions  
**Date**: 2025-10-30  
**Status**: Complete

## Overview

This document defines the data structures for the build-time version caching system. The model is intentionally simple: tool packages in, version strings out, cached in Nix store.

## Core Entities

### 1. Tool Package

**Definition**: A Nix package derivation that provides a command-line executable.

**Nix Representation**:
```nix
pkgs.go
pkgs.nodejs
pkgs.python314
```

**Properties**:
- Package derivation from nixpkgs
- Installed in devShell via `nativeBuildInputs`
- Provides executable binary in `/bin/`

### 2. Version Command

**Definition**: The specific command-line invocation to query a tool's version.

**Examples**:
```nix
"${pkgs.go}/bin/go version"
"${pkgs.nodejs}/bin/node --version"
"${pkgs.kotlin}/bin/kotlin -version 2>&1"
```

**Properties**:
- Absolute path to tool binary (Nix store path)
- Version flag or subcommand
- Optional stderr redirect (`2>&1`)

### 3. Version Cache File

**Definition**: A text file in the Nix store containing all tool version outputs for a devShell.

**Structure**:
```
go version go1.21.5 linux/amd64
node: v20.10.0
Python 3.12.1
cargo 1.75.0
```

**Properties**:
- Plain text, one line per tool
- Created by `pkgs.runCommand` at build time
- Stored in `/nix/store/<hash>-devshell-versions`
- Immutable and cacheable

**Lifecycle**:
1. Created during `nix build` of devShell
2. Stored in Nix store
3. Referenced by shellHook
4. Displayed via `cat` when shell is entered
5. Reused across all shell invocations (until tool versions change)

## Relationships

### DevShell → Tool Packages (1:N)

Each devShell declares multiple tool packages:

```nix
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.go      # Tool 1
    pkgs.nodejs  # Tool 2
    pkgs.python  # Tool 3
  ];
}
```

**Cardinality**: 1 devShell : N tools

### Tool Package → Version Command (1:1)

Each tool has exactly one version command:

```nix
{
  go = "${pkgs.go}/bin/go version";
  node = "${pkgs.nodejs}/bin/node --version";
  python = "${pkgs.python314}/bin/python --version";
}
```

**Cardinality**: 1 tool : 1 version command

### DevShell → Version Cache File (1:1)

Each devShell has one version cache file:

```nix
let
  toolVersions = pkgs.runCommand "goDev-versions" {} ''
    # Build cache for goDev
  '';
in
```

**Cardinality**: 1 devShell : 1 cache file

## Data Flow

### Build-Time Flow

```
Developer runs: nix develop .#goDev
         ↓
Nix evaluates devShell definition
         ↓
Nix builds version cache (pkgs.runCommand)
  - Executes version commands
  - Writes output to $out
  - Stores in /nix/store/<hash>
         ↓
Version cache stored permanently
```

### Runtime Flow

```
User enters shell (direnv on cd)
         ↓
shellHook executes
         ↓
cat ${toolVersions}
         ↓
Version info displayed instantly
         ↓
Shell prompt appears
```

## Implementation Structure

### Minimal Nix Implementation

```nix
{
  default = 
    let
      toolVersions = pkgs.runCommand "default-versions" {} ''
        ${pkgs.age}/bin/age --version >> $out
        ${pkgs.gnumake}/bin/make --version | head -n 1 >> $out
        ${pkgs.sops}/bin/sops --version >> $out
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
        age
        gnumake
        sops
      ];
    };
}
```

### Version Command Patterns

**Self-describing output** (includes tool name):
```nix
${pkgs.go}/bin/go version >> $out
# Output: "go version go1.21.5 linux/amd64"
```

**Needs prefix** (no tool name in output):
```nix
echo "node: $(${pkgs.nodejs}/bin/node --version)" >> $out
# Output: "node: v20.10.0"
```

**Stderr redirect** (version on stderr):
```nix
${pkgs.kotlin}/bin/kotlin -version 2>&1 >> $out
# Output: "Kotlin version 1.9.21"
```

**First line only** (multi-line output):
```nix
${pkgs.gnumake}/bin/make --version | head -n 1 >> $out
# Output: "GNU Make 4.4.1"
```

## No Complex State

This design intentionally avoids:
- ❌ Runtime version detection
- ❌ Timeouts or error handling
- ❌ Fallback logic
- ❌ Dynamic tool discovery
- ❌ Helper functions or abstractions
- ❌ Configuration options

Instead, it uses:
- ✅ Build-time execution
- ✅ Hardcoded version commands
- ✅ Nix store caching
- ✅ Simple string concatenation

## Performance Characteristics

### Build Time
- **First build**: ~100ms per tool (version command execution)
- **Cached build**: 0ms (version cache already in store)
- **Impact**: Negligible (tools themselves take longer to build)

### Runtime
- **Shell entry**: <1ms (`cat` of cached file)
- **Overhead**: Essentially zero
- **Scales**: O(1) regardless of number of tools

### Storage
- **Cache size**: ~100 bytes per tool (text file)
- **Total impact**: <1KB per devShell
- **Shared**: Same versions across all users/systems via Nix store

## Validation

### Build-Time Validation
- Nix build fails if version command is wrong
- Nix build fails if tool binary doesn't exist
- Immediate feedback during development

### Runtime Validation
- None needed - cache always exists and is valid
- Nix guarantees cache integrity

## Conclusion

The data model is minimal:
- **Input**: Tool packages + version commands
- **Process**: Execute at build time, cache in Nix store
- **Output**: Text file displayed at shell entry

No complex structures, no runtime state, no error handling. Simple and fast.

**Next Step**: Create quickstart.md with concrete usage examples.
