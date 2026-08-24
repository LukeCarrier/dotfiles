{ config, pkgs, ... }:
let
  inherit (pkgs.lib) escapeShellArg getExe;
  inherit (pkgs) agentkit-lens agentkit-litterbox;
in
{
  sops.secrets = {
    agentkit-lens-brave-search-api-key = {
      format = "yaml";
      key = "mcp/agentkit/lens/brave-search-api-key";
    };
    agentkit-lens-kagi-search-api-key = {
      format = "yaml";
      key = "mcp/agentkit/lens/kagi-search-api-key";
    };
  };

  programs.mcp.servers = {
    agentkit-lens.command = getExe (pkgs.writeShellApplication {
      name = "mcp-agentkit-lens";
      text = ''
        exec ${escapeShellArg (getExe agentkit-lens)} \
          --brave-search-api-key "$(cat ${escapeShellArg config.sops.secrets.agentkit-lens-brave-search-api-key.path})" \
          --kagi-search-api-key "$(cat ${escapeShellArg config.sops.secrets.agentkit-lens-kagi-search-api-key.path})" \
          stdio
      '';
    });
    agentkit-litterbox = {
      command = getExe agentkit-litterbox;
      args = [ "stdio" ];
    };
  };
}
