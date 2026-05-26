{ pkgs, ...}:
let
  inherit (pkgs.lib) getExe;
  inherit (pkgs)
    agentkit-lens
    agentkit-litterbox
    ;
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
    agentkit-lens = {
      command = getExe agentkit-lens;
      args = [
        "--brave-search-api-key"
        "@agentkit-lens-brave-search-api-key@"
        "--kagi-search-api-key"
        "@agentkit-lens-kagi-search-api-key@"
        "stdio"
      ];
    };
    agentkit-litterbox = {
      command = getExe agentkit-litterbox;
      args = [ "stdio" ];
    };
  };
}
