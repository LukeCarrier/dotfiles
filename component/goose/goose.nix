{
  config,
  lib,
  pkgs,
  ...
}:
let
  mcpLib = import ../../lib/mcp.nix { inherit lib; };
  substitute = mcpLib.substitute config lib;
  # programs.mcp.servers is home-manager's free-form jsonFormat.type option,
  # so we piggy-back on it as a shared source for our own generators and
  # slip in an `enabled` field HM itself doesn't define. Default to false
  # to avoid overloading agents with permissions and tool descriptions.
  buildGooseMcpConfig =
    name: serverDef:
    let
      url = serverDef.url or null;
      command = serverDef.command or null;
      isRemote = url != null;
      envs = lib.mapAttrs (_: v: substitute (toString v)) (serverDef.env or { });
      base = {
        inherit name;
        enabled = serverDef.enabled or false;
        timeout = 300;
        bundled = false;
      } // lib.optionalAttrs (envs != { }) { inherit envs; };
    in
    if isRemote then
      base
      // {
        type = "streamable_http";
        uri = substitute url;
      }
    else
      base
      // {
        type = "stdio";
        cmd = substitute (toString command);
        args = map (a: substitute (toString a)) (serverDef.args or [ ]);
      };
  gooseMcpServers = lib.mapAttrs buildGooseMcpConfig config.programs.mcp.servers;
  mcpConfigYaml = lib.concatStrings (
    lib.mapAttrsToList (name: entry: "  ${name}: ${builtins.toJSON entry}\n") gooseMcpServers
  );

  adrRecipes = ./recipes/adr;
  replaceRecipePaths = content:
    lib.strings.replaceStrings
      [
        "adr/specify.yaml"
        "adr/plan.yaml"
        "adr/tasks.yaml"
        "adr/implement.yaml"
        "adr/reflect.yaml"
        "adr/housekeeping.yaml"
      ]
      [
        "${adrRecipes}/specify.yaml"
        "${adrRecipes}/plan.yaml"
        "${adrRecipes}/tasks.yaml"
        "${adrRecipes}/implement.yaml"
        "${adrRecipes}/reflect.yaml"
        "${adrRecipes}/housekeeping.yaml"
      ]
      content;

  adrYaml = pkgs.writeTextFile {
    name = "adr.yaml";
    text = replaceRecipePaths (builtins.readFile ./recipes/adr.yaml);
  };

in
{
  sops = {
    secrets = {
      github-mcp-token = {
        format = "yaml";
        key = "mcp/github";
      };
    };
    templates."goose-config.yaml" = {
      content =
        builtins.replaceStrings
          [
            "@HOME@"
            "@MCP_CONFIG_YAML@"
          ]
          [
            config.home.homeDirectory
            mcpConfigYaml
          ]
          (builtins.readFile ./config.yaml.template);
      path = "${config.home.homeDirectory}/.config/goose/config.yaml";
    };
  };

  home = {
    packages = with pkgs; [
      claude-agent-acp
      goose-cli
      goose-desktop
    ];

    file = {
      ".config/goose/adversary.md".source = ./adversary.md;

      ".config/goose/custom_providers/custom_peacehaven_llama-swap_anthropic.json".source =
        ./custom_providers/custom_peacehaven_llama-swap_anthropic.json;
      ".config/goose/custom_providers/custom_peacehaven_llama-swap_openai.json".source =
        ./custom_providers/custom_peacehaven_llama-swap_openai.json;

      ".config/goose/recipes/adr.yaml".source = adrYaml;
      ".config/goose/recipes/adr/housekeeping.sh".source =
        ./recipes/adr/housekeeping.sh;
      ".config/goose/recipes/adr/housekeeping.yaml".source =
        ./recipes/adr/housekeeping.yaml;
      ".config/goose/recipes/adr/implement.yaml".source =
        ./recipes/adr/implement.yaml;
      ".config/goose/recipes/adr/plan.yaml".source =
        ./recipes/adr/plan.yaml;
      ".config/goose/recipes/adr/quest.yaml".source = ./recipes/adr/quest.yaml;
      ".config/goose/recipes/adr/reflect.yaml".source =
        ./recipes/adr/reflect.yaml;
      ".config/goose/recipes/adr/specify.yaml".source =
        ./recipes/adr/specify.yaml;
      ".config/goose/recipes/adr/tasks.yaml".source = ./recipes/adr/tasks.yaml;

      ".agents/skills/direnv/SKILL.md".source = ./skills/direnv/SKILL.md;

      # FIXME: migrate other agent definitions
      # ".config/goose/recipes/adrian.yaml".source = ./recipes/adrian.yaml;
      # ".config/goose/recipes/edmund.yaml".source = ./recipes/edmund.yaml;
      # ".config/goose/recipes/litterbox.yaml".source = ./recipes/litterbox.yaml;
      # ".config/goose/recipes/quest.yaml".source = ./recipes/quest.yaml;
      # ".config/goose/recipes/scout.yaml".source = ./recipes/scout.yaml;
    };
  };
}
