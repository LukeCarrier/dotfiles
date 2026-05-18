{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../../component/shell-essential/shell-essential.nix
    # ../../../../component/bash/bash.nix
    ../../../../component/fish/fish.nix
    ../../../../component/fish/default.nix
    ../../../../component/zsh/zsh.nix
    ../../../../component/direnv/direnv.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/starship/starship.nix
    ../../../../component/git/git.nix
    ../../../../component/helix/helix.nix
  ];

  home = {
    stateVersion = "24.05";

    username = "nix-on-droid";
    homeDirectory = "/data/data/com.termux.nix/files/home";
  };

  sops.defaultSopsFile = ../../../../secrets/personal.yaml;

  home.packages = lib.mkMerge [
    (with pkgs; [
      bitwarden-cli
      gh
      freshfetch
      jq
    ])
  ];

  programs.home-manager.enable = true;
}
