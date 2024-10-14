inputs@{ config, pkgs, ... }: {
  home.username = "lukecarrier";
  home.homeDirectory = "/home/lukecarrier";

  home.stateVersion = "24.05";

  programs.direnv.enable = true;

  home.packages = with pkgs; [
    bitwarden-cli btop gh freshfetch jq
    (pkgs.callPackage monaspace-fonts/monaspace-fonts.nix {
      monaspace-fonts = inputs.monaspace-fonts;
    })
    (pkgs.callPackage stklos/stklos.nix {
      stklos = inputs.stklos;
    })
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };

  programs.home-manager.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
