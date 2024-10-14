inputs@{ config, pkgs, ... }: {
  home.username = "lukecarrier";
  home.homeDirectory = "/home/lukecarrier";

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    (pkgs.callPackage monaspace-fonts/monaspace-fonts.nix {
      monaspace-fonts = inputs.monaspace-fonts;
    })
  ];

  programs.home-manager.enable = true;
}
