{ config, pkgs, ... }:
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
in
{
  home.packages = [ opencode ] ++ userFacingPkgs;

  sops = {
    secrets.opencode-github-token = {
      sopsFile = pkgs.lib.mkDefault ../../secrets/personal.yaml;
      format = "yaml";
      key = "opencode/github";
    };

    templates."opencode.jsonc" = {
      content =
        builtins.replaceStrings
          [ "@GITHUB_PERSONAL_ACCESS_TOKEN@" ]
          [ config.sops.placeholder.opencode-github-token ]
          (builtins.readFile ./opencode.jsonc.template);
      path = "${config.home.homeDirectory}/.config/opencode/opencode.jsonc";
    };
  };

  home.file = {
    ".config/opencode/AGENTS.md".source = ./AGENTS.md;
    ".config/opencode/agent/container-use.md".source = ./agent/container-use.md;
  };
}
