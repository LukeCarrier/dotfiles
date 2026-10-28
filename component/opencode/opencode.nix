{
  config,
  pkgs,
  lib,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
  mergeConfig = import ../../lib/merge-json-config.nix { inherit pkgs; };

  opencodeConfig = import ./config.nix {
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

  # Replace the Nix-owned configuration files in place. They are copied rather
  # than symlinked because the store tree is read-only and older generations
  # left read-only copies behind. cli.json is not copied: it belongs to the TUI
  # (theme, permissions, tabs are written there), so only the managed keys are
  # merged over it at activation.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${mergeConfig}

    target="$HOME/.config/opencode"
    $DRY_RUN_CMD mkdir -p "$target"

    # Earlier generations copied a read-only tree; make it replaceable.
    $DRY_RUN_CMD chmod -R u+w "$target" || true

    $DRY_RUN_CMD rm -rf "$target/agent" "$target/commands" "$target/skills"
    $DRY_RUN_CMD rm -f "$target/AGENTS.md" "$target/antigravity.json" "$target/opencode.jsonc"

    $DRY_RUN_CMD cp -r --no-preserve=mode ${opencodeConfig.immutable}/. "$target"/

    mergeJsonConfig "${opencodeConfig.cliDefaults}" "$target/cli.json"
  '';
}
