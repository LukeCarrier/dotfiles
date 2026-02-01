# OpenCode Configuration

This configuration defines the behavior of the OpenCode AI assistant.

## Architecture

```mermaid
graph TB
    subgraph Agents
        Adrian[Adrian<br/>ADR Architect<br/>gemini-2.5-flash]
        Scout[Scout<br/>Security Analyst<br/>claude-sonnet-4.5]
        Quest[Quest<br/>Quality Analyst<br/>claude-sonnet-4.5]
        Edmund[Edmund<br/>Explorer<br/>read-only]
        CU[Container Use<br/>Isolated Executor]
    end
    
    subgraph Commands
        specify[/adr.specify/]
        plan[/adr.plan/]
        tasks[/adr.tasks/]
        implement[/adr.implement/]
    end
    
    subgraph Skills
        direnv[direnv<br/>env var handling]
    end
    
    subgraph Artifacts
        spec[spec.md]
        planmd[plan.md]
        tasksmd[tasks.md]
        code[code]
    end
    
    specify -->|uses| Adrian
    plan -->|uses| Adrian
    tasks -->|uses| Adrian
    implement -.->|standalone| code
    
    Adrian -->|creates| spec
    Adrian -->|creates| planmd
    Adrian -->|creates| tasksmd
    
    CU -->|references| direnv
    
    Scout -.->|reviews| code
    Quest -.->|reviews| code
    Edmund -.->|analyzes| code
    
    spec -->|informs| planmd
    planmd -->|informs| tasksmd
    tasksmd -->|guides| implement
    
    style Adrian fill:#e1f5ff
    style Scout fill:#ffe1e1
    style Quest fill:#fff4e1
    style Edmund fill:#f0f0f0
    style CU fill:#e1ffe1
```

## Components

### Agents

Defined in `agent/*.md` with model, permissions, and tool access:

- **Adrian** - ADR architect (gemini-2.5-flash, no bash, planning only)
- **Scout** - Security analyst (claude-sonnet-4.5, full access)
- **Quest** - Quality analyst (claude-sonnet-4.5, full access)
- **Edmund** - Read-only explorer (no edit/bash/webfetch)
- **Container Use** - Isolated environment executor (container-use tools only)

### Commands

Workflows in `commands/` that trigger agents:

- `/adr.specify` → Adrian (creates spec.md)
- `/adr.plan` → Adrian (creates plan.md)
- `/adr.tasks` → Adrian (creates tasks.md)
- `/adr.implement` → general agent (executes tasks)

### Skills

Procedural knowledge in `skills/`:

- **direnv** - Environment variable handling guidance