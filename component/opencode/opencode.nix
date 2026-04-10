{
  config,
  pkgs,
  lib,
  ...
}:
let
  mcpLib = import ../../lib/mcp.nix {inherit lib;};
  substitute = mcpLib.substitute config lib;

  buildMcpConfig = _: mcpDef:
    let
      url = mcpDef.url or null;
      command = mcpDef.command or null;
      mcpType = if url != null then "remote" else "local";
      baseMcp = {type = mcpType;};
      mcpWithUrl = if url != null then baseMcp // {inherit url;} else baseMcp;
      mcpWithCommand =
        if command != null then
          mcpWithUrl // {command = map substitute ([ command ] ++ (mcpDef.args or [ ]));}
        else
          mcpWithUrl;
      mcpWithEnv =
        if (mcpDef.env or { }) != { } then
          mcpWithCommand // {environment = lib.mapAttrs (_: substitute) mcpDef.env;}
        else
          mcpWithCommand;
    in
    mcpWithEnv;

  mcpConfigurations = lib.mapAttrs buildMcpConfig config.programs.mcp.servers;

  userFacingPkgs = with pkgs; [mcp-remote];
  wrapperPkgs = with pkgs; [emcee github-mcp-server terraform-mcp-server];
  opencode = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [pkgs.opencode];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --prefix PATH : ${pkgs.lib.makeBinPath wrapperPkgs}
    '';
  };
in
{
  home.packages = [opencode pkgs.opencode-desktop] ++ userFacingPkgs;

  sops = {
    secrets = {
      opencode-github-token = {
        sopsFile = pkgs.lib.mkDefault ../../secrets/personal.yaml;
        format = "yaml";
        key = "opencode/github";
      };
    };

    templates."opencode.jsonc" = {
      content = builtins.replaceStrings ["@MCP_CONFIG_JSON@"] [(builtins.toJSON mcpConfigurations)] (
        builtins.readFile ./opencode.jsonc.template
      );
      path = "${config.home.homeDirectory}/.config/opencode/opencode.jsonc";
    };
  };

  home.file = {
    ".config/opencode/AGENTS.md".source = ./AGENTS.md;
    ".config/opencode/agent/adrian.md".source = ./agent/adrian.md;
    ".config/opencode/agent/edmund.md".source = ./agent/edmund.md;
    ".config/opencode/agent/litterbox.md".source = ./agent/litterbox.md;
    ".config/opencode/agent/quest.md".source = ./agent/quest.md;
    ".config/opencode/agent/scout.md".source = ./agent/scout.md;
    ".config/opencode/antigravity.json".source = ./antigravity.json;
    ".config/opencode/commands/adr.implement.md".source = ./commands/adr.implement.md;
    ".config/opencode/commands/adr.plan.md".source = ./commands/adr.plan.md;
    ".config/opencode/commands/adr.reflect.md".source = ./commands/adr.reflect.md;
    ".config/opencode/commands/adr.specify.md".source = ./commands/adr.specify.md;
    ".config/opencode/commands/adr.tasks.md".source = ./commands/adr.tasks.md;
    ".config/opencode/skills/direnv/SKILL.md".source = ./skills/direnv/SKILL.md;
  };
}
