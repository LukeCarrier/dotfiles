{ config, pkgs, ... }: {
  home.username = "lukecarrier";
  home.homeDirectory = "/home/lukecarrier";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
