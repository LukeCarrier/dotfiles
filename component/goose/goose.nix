{
  config,
  lib,
  pkgs,
  ...
}:
let
  mcpLib = import ../../lib/mcp.nix { inherit lib; };
  substitute = mcpLib.substitute config lib;

  buildGooseMcpConfig =
    _: serverDef:
    let
      command = serverDef.command or null;
      url = serverDef.url or null;
      isLocal = command != null;
      isRemote = url != null;
      env = lib.mapAttrs (_: v: substitute (toString v)) (serverDef.env or { });
    in
    {
      type =
        if isLocal then
          "command"
        else if isRemote then
          "http"
        else
          "unknown";
    }
    // lib.optionalAttrs isLocal {
      command = toString command;
      args = map (a: substitute (toString a)) (serverDef.args or [ ]);
    }
    // lib.optionalAttrs isRemote { inherit url; }
    // lib.optionalAttrs (env != { }) { inherit env; };

  gooseMcpServers = lib.mapAttrs buildGooseMcpConfig config.programs.mcp.servers;

  mcpConfigYaml =
    if gooseMcpServers == { } then
      ""
    else
      "mcp_servers:\n"
      + lib.concatStrings (
        lib.mapAttrsToList (
          name: server:
          "  ${name}:\n"
          + "    type: ${server.type}\n"
          + lib.optionalString (server.command or null != null) "    command: ${toString server.command}\n"
          + lib.optionalString ((server.args or [ ]) != [ ]) (
            "    args:\n" + lib.concatMapStrings (arg: "      - ${toString arg}\n") server.args
          )
          + lib.optionalString (server.url or null != null) "    url: ${toString server.url}\n"
          + lib.optionalString ((server.env or { }) != { }) (
            "    env:\n"
            +
              lib.concatMapStrings
                (pair: "      ${builtins.elemAt pair 0}: ${toString (builtins.elemAt pair 1)}\n")
                (
                  lib.mapAttrsToList (n: v: [
                    n
                    v
                  ]) server.env
                )
          )
        ) gooseMcpServers
      );
in
{
  home.packages = with pkgs; [
    claude-agent-acp
    goose-cli
  ];

  sops = {
    secrets = {
      opencode-github-token = {
        sopsFile = pkgs.lib.mkDefault ../../secrets/personal.yaml;
        format = "yaml";
        key = "opencode/github";
      };
    };

    templates."goose-config.yaml" = {
      content = builtins.replaceStrings [ "@MCP_CONFIG_YAML@" ] [ mcpConfigYaml ] (
        builtins.readFile ./config.yaml.template
      );
      path = "${config.home.homeDirectory}/.config/goose/config.yaml";
    };
  };

  home.file = {
    ".config/goose/adversary.md".source = ./adversary.md;

    ".config/goose/custom_providers/custom_peacehaven_llama-swap_anthropic.json".source =
      ./custom_providers/custom_peacehaven_llama-swap_anthropic.json;
    ".config/goose/custom_providers/custom_peacehaven_llama-swap_openai.json".source =
      ./custom_providers/custom_peacehaven_llama-swap_openai.json;

    ".config/goose/recipes/adr.yaml".source = ./recipes/adr.yaml;
    ".config/goose/recipes/adr/housekeeping.sh".source = ./recipes/adr/housekeeping.sh;
    ".config/goose/recipes/adr/housekeeping.yaml".source =
      ./recipes/adr/housekeeping.yaml;
    ".config/goose/recipes/adr/implement.yaml".source =
      ./recipes/adr/implement.yaml;
    ".config/goose/recipes/adr/plan.yaml".source = ./recipes/adr/plan.yaml;
    ".config/goose/recipes/adr/quest.yaml".source = ./recipes/adr/quest.yaml;
    ".config/goose/recipes/adr/reflect.yaml".source =
      ./recipes/adr/reflect.yaml;
    ".config/goose/recipes/adr/specify.yaml".source =
      ./recipes/adr/specify.yaml;
    ".config/goose/recipes/adr/tasks.yaml".source = ./recipes/adr/tasks.yaml;

    # FIXME: migrate other agent definitions
    # ".config/goose/recipes/adrian.yaml".source = ./recipes/adrian.yaml;
    # ".config/goose/recipes/edmund.yaml".source = ./recipes/edmund.yaml;
    # ".config/goose/recipes/litterbox.yaml".source = ./recipes/litterbox.yaml;
    # ".config/goose/recipes/quest.yaml".source = ./recipes/quest.yaml;
    # ".config/goose/recipes/scout.yaml".source = ./recipes/scout.yaml;
  };
}
