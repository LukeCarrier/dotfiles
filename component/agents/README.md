# Agent Configuration

Central configuration for AI coding agents (opencode, goose, claude-code, codex, pi).

## Architecture

Agent configurations follow a three-layer plumbing pattern:

```
lib/agents.nix
  └─ declares shared options: agents.commands, agents.definitions, agents.skills
  └─ provides substitute() for @SOPS_PLACEHOLDER@ resolution

component/agents/agents.nix
  └─ supplies concrete values for those options
  └─ single source of truth for roles, commands, and skills

component/<name>/<name>.nix
  └─ lowers shared config into agent-native format
  └─ e.g. opencode → YAML frontmatter .md files under .config/opencode/
  └─ e.g. goose → JSON recipe .yaml files under .config/goose/
```

Each harness imports `../agents/agents.nix`, reads from `config.agents.*`, and generates the agent-specific on-disk layout. The shared options module (`lib/agents.nix`) provides three option trees:

- **`config.agents.commands`** — slash commands / recipes (tool-agnostic description)
- **`config.agents.definitions`** — agent role definitions (system prompts, mode, permissions)
- **`config.agents.skills`** — procedural knowledge modules referenced by path

MCP server configuration lives under `config.programs.mcp.servers` (home-manager's free-form type) and is lowered into each agent's MCP config format by the harness. SOPS placeholders are resolved at activation time via the `substitute` function.

## Agents

| Agent | Mode | Role |
|-------|------|------|
| **Adrian** | primary | ADR architect — leads the specification → plan → tasks cycle |
| **Edmund** | primary | Read-only explorer for codebase analysis and questions |
| **Litterbox** | primary | Isolated sandbox executor for untrusted code |
| **Archie** | subagent | Architecture reviewer — structure, clarity, convention |
| **Ollie** | subagent | Operations engineer — performance, reliability, configuration, observability |
| **Paige** | subagent | Product reviewer — completeness, functional correctness (vs spec) |
| **Quest** | subagent | QA engineer — test coverage, edge cases, regression quality |
| **Scout** | subagent | Security engineer — vulnerabilities, threat model, data handling |

System prompts live in `agent/*.md`. Subagent definitions reference a model override (e.g. `claude-sonnet-4.5`) that the harness resolves against available providers.

## Commands

ADR workflow commands in `adr/*.md`, routed to Adrian for the planning steps:

| Command | Agent | Purpose |
|---------|-------|---------|
| `adr.specify` | Adrian | Build or refine `spec.toon` (rendered to `spec.md`) |
| `adr.plan` | Adrian | Create technical plan in `plan.toon` (rendered to `plan.md`) |
| `adr.tasks` | Adrian | Break plan into implementable tasks in `tasks.toon` (rendered to `tasks.md`) |
| `adr.implement` | (general) | Execute implementation per tasks |
| `adr.reflect` | Adrian | Capture learnings in `retro.toon` (rendered to `retro.md`) |
| `adr.housekeeping` | (general) | Regenerate ADR README index from `spec.toon` files |

Parameters (feature name, current date) are declared in `agents.nix` and lowered per-format.

## Skills

| Skill | Source | Purpose |
|-------|--------|---------|
| `align` | `skills/align/SKILL.md` | Relentless clarification interview to reach shared understanding |
| `code-review` | `skills/code-review/SKILL.md` | Multi-agent code review with specialised reviewers |
| `command-not-found` | `skills/command-not-found/SKILL.md` | Retry failed commands via direnv exec or nix develop |
| `jj` | `skills/jj/SKILL.md` | Jujutsu version control operations |
| `nix` | `skills/nix/SKILL.md` | Reading pinned Nix source and verifying flake configs |
| `pr-check-failure` | `skills/pr-check-failure/SKILL.md` | Diagnosing failing GitHub Actions CI checks |
| `toon` | `skills/toon/SKILL.md` | TOON format writing rules and common pitfalls |
| `writing-skills` | `skills/writing-skills/SKILL.md` | How to write skills, agent definitions, and AGENTS.md |

Skills are installed by each harness into the agent's config directory. The shared code at `skills/<name>/SKILL.md` is the canonical copy.

## Cross-cutting concerns

**SOPS secrets**: MCP server tokens are declared in `agents.nix` and substituted at activation by the harness. Add new secrets via `sops.secrets.<name>` in `agents.nix` and reference them with `@<name>@` in the server definition.

**Housekeeping script**: `adr/housekeeping.sh` synchronises the ADR README index from `spec.toon` files. Harnesses copy it into their config tree.

**ADR TOON pipeline**: All ADR artifacts (spec, plan, tasks, retro) are authored in TOON format and built to human-readable markdown via `adr/adr.build.sh` (exposed as `commands/adr.build.sh` in the fixtures), which validates each `.toon` against its JSON Schema then renders with jq. The `.toon` file is the source of truth; `.md` files are generated.

**AGENTS.md**: `AGENTS.md` contains ground-rules shared across all harnesses. Each component links it into its config directory.
