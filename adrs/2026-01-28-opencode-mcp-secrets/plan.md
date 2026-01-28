# OpenCode Dynamic MCP Configuration - Technical Plan

## 1. Architecture Overview

The proposed architecture uses the existing declarative configuration capabilities of Nix and the secure secret management provided by `sops-nix` to dynamically generate OpenCode's `opencode.jsonc` configuration. This approach ensures OpenCode is configured with the correct, environment-specific set of Model Control Plane (MCP) servers and their credentials based on the active Nix profile for a given host.

The core idea is to move from a static `opencode.jsonc.template` with simple string replacements to a fully dynamic generation of the `mcp` configuration block within `opencode.nix`. This dynamic generation involves:

1.  **Centralized Secret Storage**: MCP credentials (tokens, API keys) will be stored securely in SOPS-encrypted files (e.g., `secrets/personal.yaml`).
2.  **Declarative MCP Definitions**: Nix modules (e.g., `home-manager` modules for specific hosts or profiles) will define the *set* of MCP servers required for that environment. Each MCP definition will specify its type (`local`/`remote`), URL (if remote), command (if local, including Nix package dependencies), and reference the appropriate SOPS-managed credentials.
3.  **Dynamic JSON Construction**: `opencode.nix` will read these declarative MCP definitions, decrypt the necessary secrets via `sops-nix`, and then programmatically construct the entire `mcp` JSON object.
4.  **Configuration Injection**: The dynamically constructed `mcp` JSON object will be injected into a simplified `opencode.jsonc.template` (or directly into a Nix-generated JSON file) to produce the final `opencode.jsonc`.

This architecture ensures the number and configuration of MCP servers can vary per host/environment, and all sensitive data is handled securely and declaratively.

## 2. Technology Stack Justification

*   **Nix/NixOS/home-manager/nix-darwin**: This is the foundational technology stack of the repository. Its declarative nature, reproducibility, and ability to manage system and user environments are suited for this problem. It allows for host-specific configurations and ensures the correct OpenCode setup is applied consistently.
*   **`sops-nix`**: This tool is already in use within the repository for secure secret management. It integrates seamlessly with Nix, allowing encrypted secrets to be decrypted only during the Nix build/activation process on the target machine. `sops-nix` exposes decrypted secrets via `config.sops.secrets.<name>.text`, which directly provides the plaintext secret to Nix expressions for use in configuration. This enables secure credential handling within the Nix configuration. The current `opencode.nix` uses `config.sops.placeholder.<name>` in a `sops.templates` context for simple string replacement; this approach will be superseded by direct access to `config.sops.secrets.<name>.text` and `builtins.toJSON` for dynamic JSON object construction.
*   **Nix Language Features (`builtins.toJSON`, `lib.mkIf`, `lib.attrsets`)**: The Nix language provides powerful features for manipulating data structures. `builtins.toJSON` will convert Nix attribute sets (representing the MCP configurations) into the JSON format required by `opencode.jsonc`. Conditional logic (`lib.mkIf`) and attribute set manipulation (`lib.attrsets`) will enable dynamic selection and construction of MCP configurations based on host-specific criteria.
*   **OpenCode's `opencode.jsonc`**: This is the target configuration file format. The solution must adhere to its schema for defining MCP servers.

## 3. Component Breakdown

*   **`secrets/personal.yaml` (or other SOPS-managed files)**:
    *   **Purpose**: Stores encrypted MCP credentials (tokens, API keys, sensitive URLs).
    *   **Example Structure (SOPS encrypted)**:
        ```yaml
        opencode:
          github:
            home_token: ENC[AES256_GCM,data:...,...=]
            work_token: ENC[AES256_GCM,data:...,...=]
          atlassian:
            home_url: ENC[AES256_GCM,data:...,...=]
            home_token: ENC[AES256_GCM,data:...,...=]
        ```
    *   **Changes**: Will be extended to include new keys for each distinct MCP credential required across different environments.
*   **`opencode.nix` (main module in `@component/opencode/`)**:
    *   **Purpose**: Orchestrates the OpenCode configuration.
    *   **Changes**:
        *   Will define `sops.secrets` entries for *all* MCP credentials that need dynamic management.
            ```nix
            sops.secrets.opencode-mcp-github-home-token = {
              sopsFile = ../../secrets/personal.yaml;
              key = "opencode/github/home_token";
            };
            sops.secrets.opencode-mcp-github-work-token = {
              sopsFile = ../../secrets/personal.yaml;
              key = "opencode/github/work_token";
            };
            # ... similar for other MCPs and environments
            ```
        *   Will define a new Nix option, `opencode.mcpConfigurations`, to receive the declarative MCP definitions from host-specific modules.
            ```nix
            options.opencode.mcpConfigurations = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule ({ config, ... }: {
                options = {
                  type = lib.mkOption {
                    type = lib.types.enum [ "local" "remote" ];
                    description = "Type of the MCP server (local or remote).";
                  };
                  command = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "Command array for local MCP servers, including Nix package references.";
                    default = [ ];
                  };
                  url = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    description = "URL for remote MCP servers.";
                    default = null;
                  };
                  secretKey = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    description = "Name of the sops.secret entry containing the credential.";
                    default = null;
                  };
                  environmentKey = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    description = "Environment variable name to pass the credential (if secretKey is used).";
                    default = null;
                  };
                  # Add other MCP-specific options as needed
                };
              }));
              description = "Declarative configuration for OpenCode MCP servers.";
              default = {};
            };
            ```
        *   Will contain the core Nix logic to:
            *   Receive a list or attribute set of desired MCP configurations for the current host/profile via a new Nix option (e.g., `opencode.mcpConfigurations`).
            *   Process each MCP configuration, replacing `@PLACEHOLDER@` strings in `command` and `env` with their corresponding `config.sops.placeholder.<name>` values.
            *   Construct a Nix attribute set that mirrors the desired JSON structure for the `mcp` block in `opencode.jsonc`.
            *   **Example (simplified) of MCP construction logic in `opencode.nix`**:
                ```nix
                let
                  mcpConfigurationsForHost = config.opencode.mcpConfigurations;

                  buildMcpConfig = mcpName: mcpDef:
                    let
                      # Replace placeholders in a string
                      substitute = text: builtins.replaceStrings
                        (builtins.attrNames mcpDef.secrets)
                        (builtins.map (p: mcpDef.secrets.${p}) (builtins.attrNames mcpDef.secrets))
                        text;
                    in
                    {
                      inherit (mcpDef) type url;
                      command = builtins.map substitute mcpDef.command;
                      environment = builtins.mapAttrs (name: value: substitute value) mcpDef.env;
                    };

                  mcpJsonAttrs = pkgs.lib.attrsets.mapAttrs buildMcpConfig mcpConfigurationsForHost;
                in
                {
                  sops.templates."opencode.jsonc" = {
                    content = builtins.replaceStrings
                      [ "@MCP_CONFIG_JSON@" ]
                      [ (builtins.toJSON mcpJsonAttrs) ]
                      (builtins.readFile ./opencode.jsonc.template);
                    path = "${config.home.homeDirectory}/.config/opencode/opencode.jsonc";
                  };
                }
                ```
*   **`opencode.jsonc.template` (in `@component/opencode/`)**:
    *   **Purpose**: Simplified template for `opencode.jsonc`.
    *   **Example**:
        ```json
        {
          "$schema": "https://opencode.ai/config.json",
          "plugin": ["opencode-antigravity-auth@1.3.2", "opencode-gemini-auth@1.3.8"],
          "keybinds": { /* ... */ },
          "mcp": @MCP_CONFIG_JSON@, // Placeholder for dynamically generated JSON
          "tools": { /* ... */ },
          "agent": { /* ... */ },
          "instructions": ["AGENT.md", "CLAUDE.md", ".cursor/rules/*.md"],
          "provider": { /* ... */ }
        }
        ```
    *   **Changes**: The existing `mcp` block will be replaced with a single placeholder (e.g., `"@MCP_CONFIG_JSON@"`) that `opencode.nix` will fill with the dynamically generated JSON string. Other static parts of the template will remain.
*   **Host-specific Nix modules (e.g., `hosts/<hostname>/default.nix`, `home/<username>/default.nix`)**:
    *   **Purpose**: Define the specific configuration for a given host or user environment.
    *   **Example (for a "work" host)**:
        ```nix
        { config, pkgs, lib, ... }: {
          opencode.mcpConfigurations = {
            github = {
              type = "local";
              command = [ "${pkgs.github-mcp-server}/bin/github-mcp-server" "stdio" ];
              env = {
                GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
              };
              secrets = {
                "@TOKEN@" = config.sops.placeholder.opencode-mcp-github-work-token;
              };
            };
            coralogix-n = {
              type = "local";
              command = [ "${pkgs.github-mcp-server}/bin/github-mcp-server" "--region=eu" "stdio" ];
              env = {
                GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
                OTHER_SECRET = "@OTHER@";
              };
              secrets = {
                "@TOKEN@" = config.sops.placeholder.opencode-mcp-github-eu-token;
                "@OTHER@" = config.sops.placeholder.some-other-secret;
              };
            };
          };
        }
        ```
    *   **Changes**: These modules will be extended to define the *set* of MCP configurations (including their credentials and command details) that OpenCode should use for that particular host/profile. This will be done by setting the `opencode.mcpConfigurations` option.
*   **`flake.nix` / `Makefile`**:
    *   **Purpose**: Existing mechanisms for building and applying configurations.
    *   **Changes**: No direct changes are expected here, as the solution integrates into the existing Nix build and deployment flow.

## 4. Data Flow

```mermaid
graph TD
    subgraph Configuration Definition
        A[User defines opencode.mcpConfigurations in Host Nix modules] --> B{References sops.secrets definitions};
        B -- via secretKey --> C[sops.secrets entries in opencode.nix];
        C -- encrypts (SOPS CLI) --> D[secrets/personal.yaml (Encrypted SOPS file)];
    end

    subgraph Configuration Application (Nix Build)
        E[make host home / nixos-rebuild] --> F{Nix evaluates host-specific config (e.g., home.nix)};
        F --> G{opencode.nix module (reads opencode.mcpConfigurations)};
        G -- requests config.sops.secrets.<name>.text --> H{sops-nix decrypts relevant secrets};
        H -- decrypted text --> G;
        G -- constructs Nix attribute set for mcp --> I{builtins.toJSON serializes to JSON string};
        I --> J[opencode.jsonc.template (with @MCP_CONFIG_JSON@ placeholder)];
        J --> K[Generated ~/.config/opencode/opencode.jsonc];
    end

    subgraph Runtime
        K --> L[OpenCode reads opencode.jsonc];
        L --> M[OpenCode uses configured MCPs];
    end
```


## 6. Deployment Considerations

*   **Existing Nix Workflow**: The solution integrates directly into the existing Nix build and deployment workflow (`make host home`, `nixos-rebuild`). No new deployment steps are introduced.
*   **AGE Key Management**: Proper management of AGE private keys for SOPS decryption on each target host remains critical. This is an existing operational concern for `sops-nix` users.
*   **Rollback**: Nix's transactional updates provide an inherent rollback mechanism. If a new configuration introduces issues, reverting to a previous Nix generation will restore the previous OpenCode configuration.
*   **Secret Rotation**: When MCP credentials are rotated in the SOPS files, users must re-apply their Nix configuration for the changes to take effect in OpenCode. This is consistent with the declarative nature of Nix.