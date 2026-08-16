# Builder for agent configuration packages.
# This must be called from within a home-manager module where `config` is available.
{
  pkgs,
  config,
  lib,
}:
let
  agentsLib = import ./agents.nix { inherit lib; };

  # Build goose configuration directory  
  gooseConfig = import ./agent-config/goose.nix {
    inherit pkgs config lib agentsLib;
  };

  # Build claude-code configuration directory
  claudeCodeConfig = import ./agent-config/claude-code.nix {
    inherit pkgs config lib agentsLib;
  };

  # Build codex configuration directory
  codexConfig = import ./agent-config/codex.nix {
    inherit pkgs config lib agentsLib;
  };
in
{
  inherit claudeCodeConfig codexConfig;
  gooseConfig = gooseConfig.config;
  gooseAgents = gooseConfig.agents;
}
