{ lib, pkgs, ... }:
{
  home.stateVersion = "24.05";

  home.username = "nix-on-droid";
  home.homeDirectory = "/data/data/com.termux.nix/files/home";

  programs.direnv.enable = true;

  home.packages = lib.mkMerge [
    (
      with pkgs; [
        bitwarden-cli gh freshfetch jq
      ]
    )
  ];

  programs.home-manager.enable = true;
}
