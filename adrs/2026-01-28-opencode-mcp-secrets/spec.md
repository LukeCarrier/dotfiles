# OpenCode Dynamic MCP Configuration

## 1. Goals

This Architecture Decision Record (ADR) addresses management of multiple OpenCode MCP (Model Control Plane) server configurations and associated credentials across various environments (e.g., home, work, specific hosts). The solution integrates within the existing Nix and `sops-nix` ecosystem, as established by the repository's `README.md` and the `opencode` component's configuration.

Goals:

*   **Define Variable MCP Configurations**: Enable declarative definition of a variable number of MCP server configurations for OpenCode. Each configuration must encapsulate details including server URLs, authentication tokens, local command wrappers, and their Nix package dependencies.
*   **Use `sops-nix` for Secure Credentials**: Utilize existing `sops-nix` setup for encrypted and secure storage of sensitive MCP credentials (e.g., authentication tokens, API keys).
*   **Integrate with Nix for Declarative Setup**: Embed dynamic MCP configurations directly into the Nix/home-manager/nix-darwin system. This ensures OpenCode's runtime configuration (`opencode.jsonc`) is generated declaratively, reflecting correct MCP settings for the active host or environment profile.
*   **Use Existing Environment Switching**: Utilize the project's existing Nix flake and Makefile logic for environment switching to automatically configure OpenCode with the appropriate set of MCP servers and their credentials when a host's Nix configuration is applied. This eliminates manual switching steps from the user's workflow.
*   **Secure Credential Handling**: Guarantee that all MCP credentials are not exposed in plaintext in version control, build logs, or insecure system locations, adhering strictly to `sops-nix` security principles.

## 2. User Journeys

### 2.1 Configuring OpenCode for a Host Environment

1.  **User defines MCPs**: Identify MCP servers (e.g., multiple observability MCP instances, GitHub, Atlassian, custom local servers) and their credentials for a host environment (e.g., "work" or "home" profile).
2.  **Secure Credential Storage**: Encrypt necessary credentials (e.g., tokens, API keys) using the `sops` CLI. Store encrypted secrets within `secrets/` (e.g., `secrets/personal.yaml`).
3.  **Declarative Nix Configuration**: Define an attribute set in the Nix configuration (e.g., `home-manager` or `nix-darwin` module) describing all MCP server configurations for that environment. This attribute set uses `sops-nix` to integrate decrypted credentials for each MCP and specifies necessary commands or Nix package dependencies for local MCP servers.
4.  **Nix Configuration Application**: Apply the Nix configuration for the target host (e.g., `make host home` or `nixos-rebuild switch`).
5.  **Automated OpenCode Configuration**: The Nix build process dynamically constructs and injects the defined MCP configurations into `opencode.jsonc`. OpenCode then uses this configuration.

### 2.2 Seamless Environment Switching

1.  **User changes environment**: Transition machine from one environment (e.g., "home") to another (e.g., "work"), requiring a different set of OpenCode MCP configurations.
2.  **Profile Activation**: Activate the appropriate Nix profile or host configuration for the new environment.
3.  **Automatic Reconfiguration**: The Nix build system re-evaluates and applies the configuration. This dynamically constructs and updates `opencode.jsonc` with environment-specific MCP server definitions and credentials.
4.  **OpenCode Adapts**: OpenCode operates using the MCP configurations for the new environment, without manual adjustments.

## 3. Functional Requirements

*   **FR1**: The system MUST allow declarative definition of a variable number of MCP server configurations. Each MCP configuration MUST support:
    *   A unique identifier.
    *   MCP type (`local` or `remote`).
    *   For `remote` types: a server URL.
    *   For `local` types: a `command` array, including support for `@PLACEHOLDER@` substitution.
    *   An `env` attribute set for passing multiple environment variables to local MCP commands, including support for `@PLACEHOLDER@` substitution.
    *   A `secrets` mapping that defines the values for `@PLACEHOLDER@` strings, sourced from `sops-nix`.
*   **FR2**: Nix configuration MUST dynamically construct the `mcp` object within `opencode.jsonc` based on the active host or environment profile. This construction MUST incorporate all specified MCPs and their securely sourced credentials.
*   **FR3**: The system MUST securely obtain and decrypt credentials for each MCP from `sops-nix`, presenting these decrypted values to the Nix configuration for dynamic injection into `opencode.jsonc`.

## 4. Non-functional Requirements

*   **NFR1: Security**: All MCP credentials MUST be stored encrypted using `sops-nix`. Decryption MUST occur solely during the Nix build/activation process on the target machine. Plaintext values MUST NOT persist in insecure locations (e.g., build logs, temporary files, unencrypted configuration outputs).
*   **NFR2: Declarative Configuration**: Definition and management of all MCP configurations and credentials MUST be fully declarative within the Nix ecosystem.
*   **NFR3: Simplicity of Usage**: Once Nix configurations are established, users need only apply their system configuration to achieve the desired OpenCode MCP setup for a given environment. No manual intervention for secrets or server switching is required.
*   **NFR4: Auditability**: Nix configuration should clearly define which MCP servers are configured, under what conditions, and how their credentials are sourced.

## 5. Acceptance Criteria

*   **AC1**: Given a Nix configuration where `hostA` defines `github-mcp-server` with `tokenX` and `atlassian-mcp-server` with `tokenY`, when `hostA`'s Nix configuration is applied, OpenCode on `hostA` is configured with *both* `github-mcp-server` using `tokenX` and `atlassian-mcp-server` using `tokenY`.
*   **AC2**: Given a Nix configuration where `hostB` defines `github-mcp-server` with `tokenA` and a `custom-mcp-server` with `tokenB`, when `hostB`'s Nix configuration is applied, OpenCode on `hostB` is configured with *both* `github-mcp-server` using `tokenA` and `custom-mcp-server` using `tokenB`.
*   **AC3**: When an MCP credential (e.g., a GitHub token) in a SOPS-encrypted file is updated, and the relevant host's Nix configuration is reapplied, OpenCode is successfully reconfigured with the new credential without manual intervention.
*   **AC4**: No raw MCP credentials are found in any non-SOPS-encrypted files, environment variables exposed to non-root users, or easily accessible configurations on a deployed system.

## 6. Edge Cases and Error Handling

*   **EC1: Missing SOPS-managed Credentials**: If a Nix configuration attempts to reference a SOPS-managed credential that does not exist, is inaccessible, or is malformed within the SOPS file, the Nix build MUST fail with a clear, actionable error message.
*   **EC2: Undefined MCP Configuration**: If the Nix configuration for a specific host or profile does not define a complete set of MCP configurations, OpenCode should either default to an empty MCP configuration (no MCPs active) or the Nix build should produce an error if a mandatory MCP is missing.
*   **EC3: Missing Nix Package for Local MCP**: If a local MCP server's `command` array references a Nix package that is not available or correctly specified in the Nix configuration, the Nix build MUST fail, preventing a broken OpenCode setup.