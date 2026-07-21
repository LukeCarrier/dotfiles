# Agent Harness Implementation Runbook

## Overview

Agent harnesses (opencode, goose, claude-code, codex, pi) are configured in a
three-layer architecture:

1. **`lib/agents.nix`** — Declares shared NixOS/home-manager options for
   `agents.commands`, `agents.definitions`, and `agents.skills`.
2. **`component/agents/agents.nix`** — Provides the concrete values for those
   options: the ADR workflow commands, agent role definitions, and skill
   file paths. This is the single source of truth.
3. **`component/<name>/<name>.nix`** — Lowers the shared options into the
   agent-specific on-disk format (prompts, recipes, skills, MCP config).

Each harness imports `../agents/agents.nix` to pull in the centralized config,
then reads from `config.agents.*` to generate its files.

## Checklist

### 1. Research agent config paths

Before writing any Nix, determine where the agent reads:

| Capability | Typical paths | Notes |
|---|---|---|
| Binary | `pkgs.<name>` | Check nixpkgs first |
| Skills | `~/.config/<name>/skills/` | Usually `skills/{name}/SKILL.md` |
| Commands | `~/.config/<name>/commands/` | Per-agent format varies |
| Agents | `~/.config/<name>/agents/` | Subagent definitions |
| MCP | `~/.config/<name>/mcp.json` | JSON or config file section |
| AGENTS.md | `~/.config/<name>/AGENTS.md` or project root | Usually the config dir |

Check the agent's docs and existing harnesses in `component/` for patterns.

### 2. Create `component/<name>/<name>.nix`

Structure the module:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
  substitute = agentsLib.substitute config lib;

  buildSkillFiles = basePath:
    lib.mapAttrs' (name: path:
      lib.nameValuePair "${basePath}/${name}/SKILL.md" { source = path; }
    ) config.agents.skills;

  # Command lowering, agent lowering, MCP lowering, etc.
in
{
  imports = [ ../agents/agents.nix ];

  home.packages = with pkgs; [ <agent-package> ];

  home.file = {
    "<agent-config-dir>/AGENTS.md".source = ../agents/AGENTS.md;
  }
  // buildSkillFiles "<agent-config-dir>/skills";
}
```

### 3. Implement capability lowering

Each capability from the shared config needs a lowering function specific to
the agent's native format.

#### Skills (always needed)

Every agent should install skills. The pattern is consistent across all
harnesses:

```nix
buildSkillFiles = basePath:
  lib.mapAttrs' (name: path:
    lib.nameValuePair "${basePath}/${name}/SKILL.md" { source = path; }
  ) config.agents.skills;

home.file = {
  ...
} // buildSkillFiles ".config/<name>/skills";
```

#### Commands (if agent supports slash commands)

Lower `config.agents.commands` into the agent's prompt/recipe format. See
existing harnesses for frontmatter conventions:

| Agent | Format | Path |
|---|---|---|
| opencode | `.md` with YAML frontmatter | `.config/opencode/commands/` |
| goose | Markdown recipe with frontmatter | `.config/goose/recipes/` |
| codex | `.md` with YAML frontmatter | `.config/codex/prompts/` |
| claude-code | `.md` with YAML frontmatter | `.claude/commands/` |

#### MCP servers (if agent supports MCP)

Lower `config.programs.mcp.servers` into the agent's MCP config format. Handle
secret substitution via `substitute`. See existing harnesses for patterns:

| Agent | Format | Storage |
|---|---|---|
| opencode | JSON in `opencode.json` | Direct config merge |
| goose | TOML in `config.yaml` | Activation script merge |
| codex | TOML in `config.toml` | Activation script merge |
| claude-code | JSON per-server files | `--mcp-config` CLI args |

### 4. Install the agent binary

Add the package to `home.packages`:

```nix
home.packages = with pkgs; [ <agent-package> ];
```

Check nixpkgs first. If the agent isn't packaged, add a derivation in
`package/<name>/default.nix`.

### 5. Wire into host config

Add the import in `system/<host>/user/<user>/default.nix`, keeping the agents
block alphabetized:

```nix
imports = [
    ...
    ../../../../component/agentkit/agentkit.nix
    ../../../../component/claude-code/claude-code.nix
    ../../../../component/codex/codex.nix
    ../../../../component/goose/goose.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/pi/pi.nix
    ...
];
```

### 6. Test

Run `make home` and verify:

- Agent binary is on `PATH`
- Skills appear in the correct directory
- Commands load (if implemented)
- MCP servers activate (if implemented)
- `nix-instantiate --parse` succeeds on the new component

## Reference: existing harnesses

| Harness | File | Capabilities |
|---|---|---|
| opencode | `component/opencode/opencode.nix` | commands, agents, skills, MCP |
| goose | `component/goose/goose.nix` | commands, agents, skills, MCP |
| claude-code | `component/claude-code/claude-code.nix` | commands, skills, MCP |
| codex | `component/codex/codex.nix` | commands, agents, skills, MCP |
| pi | `component/pi/pi.nix` | skills |

## Cross-cutting concerns

### SOPS secrets

Secrets for MCP servers are declared centrally in `component/agents/agents.nix`
and referenced in harnesses via `@placeholder@` substitution. The `substitute`
function from `lib/agents.nix` resolves these at activation time.

### Per-agent paths

Each harness should install files under its own namespace:
- `.config/opencode/` for opencode
- `.config/goose/` for goose
- `.config/codex/` for codex (XDG path)
- `.claude/` for claude-code
- `.pi/agent/` for pi

Do not share paths — use the agent-specific config directory.

### Housekeeping script

The shared `component/agents/adr/housekeeping.sh` script should be copied into
the agent's config dir as a reference. It's not executable by the agent
directly but serves as documentation.
