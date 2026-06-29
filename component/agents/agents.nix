{
  config,
  lib,
  pkgs,
  ...
}:
# Agent definition data. This is pure data: it populates the tool-agnostic
# `agents.definitions` option (declared in lib/agents.nix), which each component
# lowers into its own on-disk format — mirroring how `agents.commands` works.
#
# Each agent's body (system prompt) lives as Markdown under ./agent/<name>.md;
# metadata (mode, temperature, tools, permissions) is defined here alongside the
# body reference so both are in one module. OpenCode renders the full .md with
# frontmatter; Goose wraps the body in a recipe; etc.
let
  body = name: builtins.readFile (./agent + "/${name}.md");
in
{
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

    quest = {
      description = "Quality Analyst";
      mode = "subagent";
      model = "github-copilot/claude-sonnet-4.5";
      temperature = 0.1;
      body = body "quest";
      permission = {
        bash = "allow";
        edit = "allow";
        webfetch = "allow";
      };
    };

    scout = {
      description = "Security Analyst";
      mode = "subagent";
      model = "github-copilot/claude-sonnet-4.5";
      temperature = 0.1;
      body = body "scout";
      permission = {
        bash = "allow";
        edit = "allow";
        webfetch = "allow";
      };
    };
  };
}
