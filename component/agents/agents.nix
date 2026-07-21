{
  lib,
  pkgs,
  ...
}:
let
  body = name: builtins.readFile (./agent + "/${name}.md");
  adrBody = name: builtins.readFile (./adr + "/${name}.md");

  featureParams = [
    {
      key = "feature_name";
      description = "Feature name";
    }
    {
      key = "current_date";
      description = "Current date in YYYY-MM-DD format";
    }
  ];

  # Review subagents: read-only on codebase, return findings via Task tool.
  reviewPermissions = {
    bash = "allow";
    edit = "deny";
    write = "deny";
    webfetch = "allow";
  };
in
{
  imports = [
    (import ../../lib/agents.nix { inherit lib; }).commandsModule
    (import ../../lib/agents.nix { inherit lib; }).definitionsModule
  ];

  sops.secrets.github-mcp-token = {
    format = "yaml";
    key = "mcp/github";
  };

  programs.mcp.servers.github = {
    command = lib.getExe pkgs.github-mcp-server;
    args = [
      "stdio"
      "--toolsets=default,actions"
    ];
    env.GITHUB_PERSONAL_ACCESS_TOKEN = "@github-mcp-token@";
  };

  agents.skills = {
    code-review = ./skills/code-review/SKILL.md;
    direnv = ./skills/direnv/SKILL.md;
    jj = ./skills/jj/SKILL.md;
    pr-check-failure = ./skills/pr-check-failure/SKILL.md;
  };

  agents.commands = {
    "adr.specify" = {
      title = "ADR Specify";
      description = "Generate or refine an ADR specification";
      body = adrBody "specify";
      agent = "adrian";
    };
    "adr.plan" = {
      title = "ADR Plan";
      description = "Create a technical plan based on an ADR specification";
      body = adrBody "plan";
      agent = "adrian";
      parameters = featureParams;
    };
    "adr.tasks" = {
      title = "ADR Tasks";
      description = "Break an ADR plan into implementable tasks";
      body = adrBody "tasks";
      agent = "adrian";
      parameters = featureParams;
    };
    "adr.implement" = {
      title = "ADR Implement";
      description = "Implement an ADR following defined tasks";
      body = adrBody "implement";
      maxTurns = 100;
      timeout = 600;
      parameters = featureParams;
    };
    "adr.reflect" = {
      title = "ADR Reflect";
      description = "Capture learnings and improve the ADR process";
      body = adrBody "reflect";
      agent = "adrian";
      parameters = featureParams;
    };
    "adr.housekeeping" = {
      title = "ADR Housekeeping";
      description = "Maintains adrs/README.md with all ADRs grouped by status";
      prompt = "Run the housekeeping script to regenerate the ADR README";
      body = adrBody "housekeeping";
      maxTurns = 10;
      timeout = 60;
    };
  };

  agents.definitions = {
    adrian = {
      description = "Architecture Decision Records";
      mode = "primary";
      temperature = 0.1;
      body = body "adrian";
      permission = {
        bash = "deny";
        edit = {
          "*" = "ask";
          "adrs/*" = "allow";
        };
        webfetch = "allow";
      };
    };

    edmund = {
      description = "Explorer";
      mode = "primary";
      temperature = 0.1;
      body = body "edmund";
      permission = {
        bash = "deny";
        edit = "deny";
        webfetch = "deny";
      };
    };

    litterbox = {
      description = "Litterbox";
      mode = "primary";
      temperature = 0.1;
      body = body "litterbox";
      tools = {
        "*" = false;
        read = true;
        edit = false;
        write = false;
        webfetch = true;
        google_search = true;
        question = true;
        todowrite = true;
        todoread = true;
        task = true;
        discard = true;
        extract = true;
        skill = true;
        "litterbox_*" = true;
      };
      permission = {
        "*" = "ask";
        read = "allow";
        edit = "deny";
        write = "deny";
        webfetch = "allow";
        google_search = "allow";
        question = "allow";
        todowrite = "allow";
        todoread = "allow";
        task = "allow";
        discard = "allow";
        extract = "allow";
        skill = "allow";
        "litterbox_*" = "allow";
        "litterbox_sandbox-create" = "ask";
      };
    };

    archie = {
      description = "Architecture Reviewer";
      mode = "subagent";
      temperature = 0.1;
      body = body "archie";
      permission = reviewPermissions;
    };

    ollie = {
      description = "Operations Engineer";
      mode = "subagent";
      temperature = 0.1;
      body = body "ollie";
      permission = reviewPermissions;
    };

    paige = {
      description = "Product Reviewer";
      mode = "subagent";
      temperature = 0.1;
      body = body "paige";
      permission = reviewPermissions;
    };

    quest = {
      description = "QA Engineer";
      mode = "subagent";
      temperature = 0.1;
      body = body "quest";
      permission = reviewPermissions;
    };

    scout = {
      description = "Security Engineer";
      mode = "subagent";
      temperature = 0.1;
      body = body "scout";
      permission = reviewPermissions;
    };
  };
}
