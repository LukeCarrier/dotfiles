{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
  substitute = agentsLib.substitute config lib;
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
      }
      // lib.optionalAttrs (envs != { }) { inherit envs; };
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

  # Lower a tool-agnostic command definition (config.agents.commands) into a
  # Goose recipe. Goose reads YAML, and JSON is valid YAML, so we emit JSON via
  # toJSON — the same approach used for the MCP config blocks above.
  buildGooseRecipe =
    cmd:
    builtins.toJSON (
      {
        version = "1.0.0";
        title = cmd.title;
        description = cmd.description;
        settings.max_turns = cmd.maxTurns;
        instructions = cmd.body;
        prompt = if cmd.prompt == null then cmd.description else cmd.prompt;
        extensions = [
          {
            type = "builtin";
            name = "developer";
            timeout = cmd.timeout;
            bundled = true;
          }
        ];
      }
      // lib.optionalAttrs (cmd.parameters != [ ]) { parameters = cmd.parameters; }
    );

  # Dotted command names map onto nested recipe paths: `adr.specify` lives at
  # `recipes/adr/specify.yaml`.
  recipePath = name: "${lib.replaceStrings [ "." ] [ "/" ] name}.yaml";
  recipeFiles = lib.mapAttrs (
    name: cmd: pkgs.writeText "${name}.yaml" (buildGooseRecipe cmd)
  ) config.agents.commands;

  # Aggregate recipes (e.g. adr.yaml) reference their sub-recipes by relative
  # path; rewrite each to the generated recipe in the Nix store.
  replaceRecipePaths =
    content:
    let
      names = lib.attrNames config.agents.commands;
    in
    lib.strings.replaceStrings (map recipePath names) (map (
      name: "${recipeFiles.${name}}"
    ) names) content;

  adrYaml = pkgs.writeTextFile {
    name = "adr.yaml";
    text = replaceRecipePaths (builtins.readFile ./recipes/adr.yaml);
  };

in
{
  imports = [ ../agents ];

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
      ".config/goose/recipes/adr/housekeeping.sh".source = ../agents/adr/housekeeping.sh;
      ".config/goose/recipes/adr/quest.yaml".source = ./recipes/adr/quest.yaml;

      ".agents/skills/direnv/SKILL.md".source = ./skills/direnv/SKILL.md;

      # FIXME: migrate other agent definitions
      # ".config/goose/recipes/adrian.yaml".source = ./recipes/adrian.yaml;
      # ".config/goose/recipes/edmund.yaml".source = ./recipes/edmund.yaml;
      # ".config/goose/recipes/litterbox.yaml".source = ./recipes/litterbox.yaml;
      # ".config/goose/recipes/quest.yaml".source = ./recipes/quest.yaml;
      # ".config/goose/recipes/scout.yaml".source = ./recipes/scout.yaml;
    }
    // lib.mapAttrs' (
      name: file: lib.nameValuePair ".config/goose/recipes/${recipePath name}" { source = file; }
    ) recipeFiles;
  };
}
