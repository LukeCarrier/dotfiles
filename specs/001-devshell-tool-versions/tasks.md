# Implementation Tasks: DevShell Tool Version Display

**Feature**: 001-devshell-tool-versions  
**Generated**: 2025-10-30  
**Status**: Ready for implementation

## Overview

This document breaks down the implementation of automated tool version display for Nix devShells into discrete, executable tasks. The implementation uses build-time version caching to achieve zero runtime overhead, making it ideal for direnv-based workflows.

## Task Summary

- **Total Tasks**: 8
- **Parallelizable Tasks**: 4 (50%)
- **User Stories**: 3 (P1, P2, P3)
- **Estimated MVP**: User Story 1 only (Tasks T001-T003)

## Implementation Strategy

### Incremental Delivery Approach

1. **MVP (User Story 1)**: Basic version display for all devShells
   - Delivers core value: immediate environment visibility
   - Testable independently: enter shell, see versions
   - Tasks: T001-T003

2. **Enhancement (User Story 2)**: Format consistency
   - Improves readability and UX
   - Testable: verify consistent output format
   - Tasks: T004-T005

3. **Robustness (User Story 3)**: Edge case handling
   - Handles tools with unusual version commands
   - Testable: verify build handles edge cases
   - Tasks: T006-T007

4. **Completion**: Documentation and validation
   - Task: T008

### Dependencies Between User Stories

```
User Story 1 (P1) → User Story 2 (P2) → User Story 3 (P3)
     [MVP]              [Enhancement]        [Robustness]
```

- US2 depends on US1 (must have version display before formatting it)
- US3 depends on US2 (format must be established before handling edge cases)
- **No parallel story implementation**: Stories are sequential improvements

---

## Phase 1: Setup

No setup phase needed - modifying existing file.

---

## Phase 2: User Story 1 - View Tool Versions on Shell Entry (P1)

**Story Goal**: When a developer enters any devShell, they immediately see all tool versions displayed automatically.

**Independent Test Criteria**:
1. Enter each devShell (default, goDev, nodeDev, kotlinDev, pythonDev, rustDev)
2. Verify version information appears before prompt
3. Verify all tools in that devShell are listed

**Acceptance**: 
- All 6 devShells display tool versions automatically
- Version display completes in <1 second (instant via `cat`)
- Shell initialization never fails due to version display

### Tasks

- [X] T001 [US1] Read current shell/default.nix to understand existing structure and identify all 6 devShells in shell/default.nix
- [X] T002 [US1] Implement build-time version cache for default devShell in shell/default.nix using pkgs.runCommand with hardcoded version commands for all 9 tools (age, gnumake, nil, nixd, nix-index, nixfmt-rfc-style, ssh-to-age, sops, treefmt)
- [X] T003 [US1] Add shellHook with cat command to display cached versions for default devShell in shell/default.nix

### Manual Testing for US1

After completing T001-T003:
```bash
# Test default shell
nix develop

# Expected: See versions of age, gnumake, nil, nixd, nix-index, nixfmt, ssh-to-age, sops, treefmt
# Expected: Versions appear before prompt
# Expected: Shell initializes successfully
```

---

## Phase 3: User Story 2 - Clear Version Format (P2)

**Story Goal**: Version information is displayed in a consistent, readable format across all devShells with one tool per line.

**Independent Test Criteria**:
1. Review output from all 6 devShells
2. Verify one tool per line
3. Verify tools with self-describing output (e.g., "go version") have no prefix
4. Verify tools without tool name (e.g., "v20.10.0") have prefix (e.g., "node: ")

**Acceptance**:
- Output is consistent across all devShells
- Each tool on separate line
- Prefixes added only when needed
- Multi-line output reduced to first line

**Dependencies**: Requires US1 complete (T001-T003)

### Tasks

- [X] T004 [P] [US2] Implement build-time version cache for goDev in shell/default.nix with hardcoded commands for delve, go, golangci-lint, gopls, gnumake
- [X] T005 [P] [US2] Implement build-time version cache for nodeDev in shell/default.nix with hardcoded commands for bun, node, pnpm, yarn, typescript-language-server
- [X] T006 [P] [US2] Implement build-time version cache for kotlinDev in shell/default.nix with hardcoded commands for kotlin, kotlin-language-server
- [X] T007 [P] [US2] Implement build-time version cache for pythonDev in shell/default.nix with hardcoded commands for python, jedi-language-server, python-lsp-server, ruff

### Manual Testing for US2

After completing T004-T007:
```bash
# Test each shell
nix develop .#goDev
nix develop .#nodeDev
nix develop .#kotlinDev
nix develop .#pythonDev

# Expected: Consistent format across all shells
# Expected: One tool per line
# Expected: Proper prefixes (e.g., "node: v20.10.0" but "go version go1.21.5")
```

---

## Phase 4: User Story 3 - Handle Missing Version Information (P3)

**Story Goal**: System handles tools with non-standard version commands gracefully, ensuring build success even for edge cases.

**Independent Test Criteria**:
1. Verify build succeeds for all devShells
2. Verify tools with stderr output (kotlin -version 2>&1) work correctly
3. Verify tools with multi-line output use first line only
4. Verify tools needing prefixes get them

**Acceptance**:
- Build completes successfully for all devShells
- Tools with stderr versions display correctly
- Multi-line output reduced to single line
- No silent failures

**Dependencies**: Requires US2 complete (T004-T007)

### Tasks

- [X] T008 [US3] Implement build-time version cache for rustDev in shell/default.nix with hardcoded commands for cargo, rustc, lldb, rust-analyzer, ensuring stderr redirection and first-line extraction where needed
- [X] T009 [US3] Test build of all devShells to verify version cache creation succeeds and handles edge cases (stderr output for kotlin, multi-line for make/lldb, tools needing prefixes)

### Manual Testing for US3

After completing T008-T009:
```bash
# Test rust shell
nix develop .#rustDev

# Expected: All tools display correctly
# Expected: No build failures

# Test edge cases
nix develop .#kotlinDev  # kotlin outputs to stderr
nix develop .#goDev      # make has multi-line output

# Expected: All handle gracefully
```

---

## Phase 5: Polish & Validation

**Goal**: Verify implementation meets all success criteria and is ready for production use.

### Tasks

- [X] T010 Verify all 6 devShells display versions correctly and update quickstart.md with actual output examples if needed in specs/001-devshell-tool-versions/quickstart.md

### Final Validation

After completing all tasks:
```bash
# Validate each devShell
for shell in default goDev nodeDev kotlinDev pythonDev rustDev; do
  echo "Testing $shell..."
  nix develop .#$shell --command bash -c "exit"
done

# Expected: All shells enter successfully
# Expected: Version information displayed for each
# Expected: No errors or warnings

# Validate with direnv
cd /path/to/project/with/direnv
# Expected: Instant version display
# Expected: No noticeable delay
```

**Success Criteria Validation**:
- ✅ SC-001: Versions visible within 2 seconds (instant via cat)
- ✅ SC-002: <1 second startup time (zero overhead)
- ✅ SC-003: 100% of tools with --version display correctly
- ✅ SC-004: Shell initialization always succeeds
- ✅ SC-005: Version output is readable without parsing

---

## Parallel Execution Opportunities

### Within User Story 2 (Tasks T004-T007)

These tasks can run in parallel as they modify different devShells:

```bash
# Terminal 1
# Implement goDev version cache (T004)

# Terminal 2
# Implement nodeDev version cache (T005)

# Terminal 3
# Implement kotlinDev version cache (T006)

# Terminal 4
# Implement pythonDev version cache (T007)
```

**Parallelization Rules**:
- T004-T007 are independent (different devShells)
- All must complete before moving to US3
- Each terminal works on a different devShell definition

---

## Task Details Reference

### Version Command Reference (from research.md)

**Tools with self-describing output** (no prefix needed):
```nix
${pkgs.go}/bin/go version           # → "go version go1.21.5..."
${pkgs.python314}/bin/python --version  # → "Python 3.12.1"
${pkgs.gnumake}/bin/make --version | head -n 1  # → "GNU Make 4.4.1"
${pkgs.cargo}/bin/cargo --version   # → "cargo 1.75.0"
```

**Tools needing prefix** (version lacks tool name):
```nix
echo "node: $(${pkgs.nodejs}/bin/node --version)"  # → "node: v20.10.0"
echo "pnpm: $(${pkgs.pnpm}/bin/pnpm --version)"    # → "pnpm: 8.14.0"
```

**Tools with stderr output**:
```nix
${pkgs.kotlin}/bin/kotlin -version 2>&1  # → "Kotlin version 1.9.21"
```

**Tools with multi-line output**:
```nix
${pkgs.gnumake}/bin/make --version | head -n 1  # Take first line only
${pkgs.lldb_19}/bin/lldb --version | head -n 1  # Take first line only
```

### Implementation Pattern Template

```nix
{
  shellName = 
    let
      toolVersions = pkgs.runCommand "shellName-versions" {} ''
        # Self-describing tools (no prefix)
        ${pkgs.tool}/bin/tool --version >> $out
        
        # Tools needing prefix
        echo "tool: $(${pkgs.tool}/bin/tool --version)" >> $out
        
        # Tools with stderr
        ${pkgs.tool}/bin/tool -version 2>&1 >> $out
        
        # Tools with multi-line
        ${pkgs.tool}/bin/tool --version | head -n 1 >> $out
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
        # existing tools
      ];
    };
}
```

---

## Notes

- **Build-time execution**: All version detection happens during `nix build`, not at shell entry
- **Zero runtime overhead**: Display is instant via `cat` of cached file
- **No error handling needed**: Build fails if version command wrong (caught during development)
- **Nix store caching**: Version cache shared across all shell invocations until tool versions change
- **direnv optimization**: Perfect for direnv workflows where shell entry must be instant

## Implementation Tips

1. **Start with default shell** (T002-T003): Simplest devShell, validates approach
2. **Test build incrementally**: Run `nix develop` after each devShell implementation
3. **Use research.md tool matrix**: Reference for exact version commands per tool
4. **Check stderr vs stdout**: Some tools (kotlin) output version to stderr
5. **Handle multi-line output**: Use `head -n 1` for tools like make and lldb
6. **Add prefixes selectively**: Only for tools that don't include name in output

## Completion Checklist

After all tasks complete:

- [ ] All 6 devShells display tool versions
- [ ] Version display is instant (<1ms via cat)
- [ ] Build succeeds for all devShells
- [ ] Output format is consistent and readable
- [ ] Tools with stderr output work correctly
- [ ] Multi-line output reduced to first line
- [ ] Prefixes added only when needed
- [ ] Documentation (quickstart.md) updated with examples
- [ ] Manual testing completed for all scenarios
- [ ] Ready for production use
