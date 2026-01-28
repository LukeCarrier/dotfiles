{ config, pkgs, lib, ... }:
let
  userFacingPkgs = with pkgs; [
    container-use
    mcp-remote
  ];
  wrapperPkgs = with pkgs; [
    emcee
    github-mcp-server
    terraform-mcp-server
  ];
  opencode = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [ pkgs.opencode ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --prefix PATH : ${pkgs.lib.makeBinPath wrapperPkgs}
    '';
  };

  buildMcpConfig = mcpName: mcpDef:
    let
      placeholders = builtins.attrNames mcpDef.secrets;
      replacements = map (p: mcpDef.secrets.${p}) placeholders;
      
      substituteString = text:
        if placeholders != [] then
          builtins.replaceStrings placeholders replacements text
        else
          text;
      
      baseMcp = {
        inherit (mcpDef) type;
      };
      
      mcpWithUrl = if mcpDef.url != null then
        baseMcp // { url = mcpDef.url; }
      else
        baseMcp;
      
      mcpWithCommand = if mcpDef.command != [] then
        mcpWithUrl // { command = map substituteString mcpDef.command; }
      else
        mcpWithUrl;
      
      mcpWithEnv = if mcpDef.env != {} then
        mcpWithCommand // { environment = lib.mapAttrs (name: value: substituteString value) mcpDef.env; }
      else
        mcpWithCommand;
    in
    mcpWithEnv;

  mcpConfigurations = lib.mapAttrs buildMcpConfig config.opencode.mcpConfigurations;
in
{
  options.opencode.mcpConfigurations = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        type = lib.mkOption {
          type = lib.types.enum [ "local" "remote" ];
          description = "Type of the MCP server (local or remote).";
        };
        command = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Command line arguments for local MCP servers (including executable). Supports @PLACEHOLDER@ strings for secret substitution.";
          default = [ ];
        };
        url = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "URL for remote MCP servers.";
          default = null;
        };
        env = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Environment variables to pass to local MCP commands. Values can include @PLACEHOLDER@ strings for secret substitution.";
          default = { };
        };
        secrets = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Mapping of @PLACEHOLDER@ strings to their corresponding sops.placeholder values.";
          default = { };
        };
      };
    });
    description = "Declarative configuration for OpenCode MCP servers.";
    default = { };
  };

  config = {
    home.packages = [ opencode ] ++ userFacingPkgs;

    sops = {
      # Example: to add a new MCP credential, define it here and reference via
      # config.sops.placeholder.<secret-name> in opencode.mcpConfigurations
      secrets.opencode-github-token = {
        sopsFile = pkgs.lib.mkDefault ../../secrets/personal.yaml;
        format = "yaml";
        key = "opencode/github";
      };

      templates."opencode.jsonc" = {
        content =
          builtins.replaceStrings
            [ "@MCP_CONFIG_JSON@" ]
            [ (builtins.toJSON mcpConfigurations) ]
            (builtins.readFile ./opencode.jsonc.template);
        path = "${config.home.homeDirectory}/.config/opencode/opencode.jsonc";
      };
    };

    home.file = {
      ".config/opencode/AGENTS.md".source = ./AGENTS.md;
      ".config/opencode/agent/container-use.md".source = ./agent/container-use.md;
      ".config/opencode/agent/explore.md".source = ./agent/explore.md;
    };
  };
}
