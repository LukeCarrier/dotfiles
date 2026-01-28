# ADR: OpenCode Dynamic MCP Configuration - Tasks

## 1. Task List

### Task 1: Define `opencode.mcpConfigurations` Nix Option
- **Description**: In `opencode.nix`, define the `lib.mkOption` for `opencode.mcpConfigurations`. Use a submodule to represent individual MCP server configurations with fields for `type`, `command` (list), `url`, `env` (attrset), and `secrets` (attrset mapping placeholders to values).
- **Success Criteria**: Nix configuration evaluates successfully with the new option defined.
- **Complexity**: Low
- **Effort**: 1-2 hours
- **Reference**: `spec.md` FR1, `plan.md` Section 3

### Task 2: Define SOPS Secrets for MCP Credentials
- **Description**: In `opencode.nix`, define `sops.secrets` entries for all required MCP credentials, mapping them to the appropriate keys in `secrets/personal.yaml` (or other SOPS-managed files).
- **Success Criteria**: `sops-nix` correctly identifies these secrets.
- **Complexity**: Low
- **Effort**: 1-2 hours
- **Reference**: `spec.md` FR3, `plan.md` Section 3

### Task 3: Implement Dynamic MCP JSON Construction Logic
- **Description**: In `opencode.nix`, implement the Nix logic to iterate over `config.opencode.mcpConfigurations`. For each entry, perform `@PLACEHOLDER@` substitution in `command` and `env` using the values provided in the `secrets` attribute set.
- **Success Criteria**: The constructed Nix attribute set accurately represents all defined MCPs, with placeholders correctly prepared for `sops-nix` template processing.
- **Dependencies**: Task 1, Task 2
- **Complexity**: Medium
- **Effort**: 2-4 hours
- **Reference**: `spec.md` FR2, `plan.md` Section 3

### Task 4: Update `opencode.jsonc.template`
- **Description**: Simplify `opencode.jsonc.template` by replacing the entire hardcoded `mcp` block with a single `@MCP_CONFIG_JSON@` placeholder.
- **Success Criteria**: The template is updated and contains the correct placeholder for the `mcp` key.
- **Complexity**: Low
- **Effort**: < 1 hour
- **Reference**: `plan.md` Section 3

### Task 5: Integrate Dynamic JSON into `opencode.jsonc` Generation
- **Description**: In `opencode.nix`, update the generation of `~/.config/opencode/opencode.jsonc`. Use `builtins.replaceStrings` to substitute the `@MCP_CONFIG_JSON@` placeholder in the template with the result of `builtins.toJSON` applied to the dynamic MCP attribute set.
- **Success Criteria**: The generated `opencode.jsonc` file in the user's home directory contains the correct, dynamically populated `mcp` block.
- **Dependencies**: Task 3, Task 4
- **Complexity**: Low
- **Effort**: 1-2 hours
- **Reference**: `spec.md` FR2, `plan.md` Section 3

### Task 6: Migrate Host-Specific Configurations
- **Description**: Identify and update host-specific or profile-specific Nix modules to use the new `opencode.mcpConfigurations` option. Define the required MCPs and their credentials for each environment.
- **Success Criteria**: Each target host/profile correctly defines its required MCP set, and the resulting `opencode.jsonc` is accurate for that environment.
- **Dependencies**: Task 5
- **Complexity**: Medium
- **Effort**: 2-4 hours
- **Reference**: `spec.md` User Journeys, `plan.md` Section 3

### Task 7: Final Verification and Cleanup
- **Description**: Verify the full implementation by applying the configuration to different hosts (e.g., home and work). Ensure OpenCode correctly loads and uses the environment-specific MCPs. Remove any obsolete configuration logic or placeholders from `opencode.nix` and `opencode.jsonc.template`.
- **Success Criteria**: OpenCode operates correctly across all target environments. The codebase is clean of legacy MCP configuration methods.
- **Dependencies**: Task 6
- **Complexity**: Low
- **Effort**: 1-2 hours
- **Reference**: `spec.md` Acceptance Criteria

## 2. Dependencies and Management

- The implementation follows a sequential flow from defining the infrastructure (Options, Secrets) to the logic (Construction, Integration) and finally the configuration of specific environments (Migration, Verification).
- **Critical Path**: Tasks 1, 3, 5, and 6 form the critical path for delivering the dynamic configuration capability.
- **Test Requirements**: Each task that modifies Nix logic should be validated by evaluating the Nix configuration (e.g., `nix-instantiate --eval`) and inspecting the resulting generated files in the Nix store.
