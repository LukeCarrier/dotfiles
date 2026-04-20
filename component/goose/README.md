# Goose Agent Definitions

This directory contains agent configuration files for goose.

## Agents

### adrian
- **Role**: ADR Architect
- **Purpose**: Lead the ADR planning cycle, manage specification, planning, and task breakdown
- **Mode**: primary
- **Temperature**: 0.1
- **Tools**: All tools (`*`)
- **Permissions**:
  - `bash`: deny
  - `edit`: ask (allow for `adrs/*` paths)
  - `webfetch`: allow

### edmund
- **Role**: Explorer
- **Purpose**: Read-only codebase exploration and analysis
- **Mode**: primary
- **Temperature**: 0.1
- **Tools**: All tools (`*`)
- **Permissions**:
  - `bash`: deny
  - `edit`: deny
  - `webfetch`: deny

### quest
- **Role**: Quality Analyst
- **Purpose**: QA review, identify quality risks and testing gaps
- **Mode**: subagent
- **Temperature**: 0.1
- **Tools**: All tools (`*`)
- **Permissions**:
  - `bash`: allow
  - `edit`: allow
  - `webfetch`: allow

### scout
- **Role**: Security Analyst
- **Purpose**: Security review, identify vulnerabilities and propose mitigations
- **Mode**: subagent
- **Temperature**: 0.1
- **Tools**: All tools (`*`)
- **Permissions**:
  - `bash`: allow
  - `edit`: allow
  - `webfetch`: allow

## ADR Recipe

The ADR workflow is implemented as a recipe with subrecipes:

- `adr_specify` — Generate or refine the specification
- `adr_plan` — Create technical plan
- `adr_tasks` — Break into implementable tasks
- `adr_implement` — Execute implementation
- `adr_reflect` — Capture learnings
- `adr_housekeeping` — Update ADR README
- `adr_quest` — Run quest subagent for QA review
- `adr_scout` — Run scout subagent for security review

See `adrs/recipes/recipe.yaml` for the full recipe configuration.
