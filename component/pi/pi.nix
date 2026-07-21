{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };

  buildSkillFiles = basePath:
    lib.mapAttrs' (name: path:
      lib.nameValuePair "${basePath}/${name}/SKILL.md" { source = path; }
    ) config.agents.skills;
in
{
  imports = [ ../agents/agents.nix ];

  home.packages = with pkgs; [ pi-coding-agent ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ../agents/AGENTS.md;
  }
  // buildSkillFiles ".pi/agent/skills";
}
