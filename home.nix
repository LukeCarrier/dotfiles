inputs@{ config, pkgs, ... }: {
  home.username = "lukecarrier";
  home.homeDirectory = "/home/lukecarrier";

  home.stateVersion = "24.05";

  programs.direnv.enable = true;

  home.packages = with pkgs; [
    (pkgs.callPackage monaspace-fonts/monaspace-fonts.nix {
      monaspace-fonts = inputs.monaspace-fonts;
    })
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };

  programs.home-manager.enable = true;
}
