{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Build the goose configuration packages
  agentConfig = import ../../lib/agent-config.nix {
    inherit pkgs config lib;
  };
  gooseConfigPkg = agentConfig.gooseConfig;
  gooseAgentsPkg = agentConfig.gooseAgents;

in
{
  imports = [ ../agents/agents.nix ];

  home = {
    packages = with pkgs; [
      claude-agent-acp
      goose-cli
      goose-desktop
    ];

    # Copy the built configuration during activation
    # (can't symlink - goose may write state files there)
    activation.gooseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD rm -rf "$HOME/.config/goose"
      $DRY_RUN_CMD cp -r ${gooseConfigPkg} "$HOME/.config/goose"
      $DRY_RUN_CMD chmod -R u+w "$HOME/.config/goose"
      
      $DRY_RUN_CMD rm -rf "$HOME/.agents"
      $DRY_RUN_CMD cp -r ${gooseAgentsPkg} "$HOME/.agents"
      $DRY_RUN_CMD chmod -R u+w "$HOME/.agents"
    '';
  };
}
