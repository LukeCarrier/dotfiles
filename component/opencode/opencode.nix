{
  config,
  pkgs,
  lib,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
  opencodeConfigPkg = import ./config.nix {
    inherit pkgs config lib agentsLib;
  };

  userFacingPkgs = with pkgs; [ mcp-remote ];
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
in
{
  imports = [ ../agents/agents.nix ];

  home.packages = [
    opencode
    pkgs.opencode-desktop
  ]
  ++ userFacingPkgs;

  # Copy the built configuration to ~/.config/opencode during activation
  # (can't symlink - opencode writes .gitignore and state files there)
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/opencode"
    mkdir -p "$(dirname "$target")"
    
    # Remove old config and copy new one with writable permissions
    $DRY_RUN_CMD rm -rf "$target"
    $DRY_RUN_CMD cp -r ${opencodeConfigPkg} "$target"
    $DRY_RUN_CMD chmod -R u+w "$target"
  '';
}
