inputs@{ config, lib, pkgs, ... }: {
  home.stateVersion = "24.05";

  home.username = "lukecarrier";
  home.homeDirectory = "/home/lukecarrier";

  programs.direnv.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "jetbrains-toolbox"
  ];

  home.packages = with pkgs; [
    bitwarden-cli btop gh freshfetch jq
    ungoogled-chromium
    jetbrains-toolbox
    gnome-network-displays
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };

  programs.home-manager.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
