{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    crimson-pro

    fira-code
    fira-code-symbols

    font-awesome

    inter

    liberation_ttf

    monaspace
    nerd-fonts.monaspace

    mplus-outline-fonts.githubRelease

    noto-fonts
    noto-fonts-color-emoji

    proggyfonts
  ];

  fonts.fontconfig = {
    enable = true;
    antialiasing = lib.mkDefault true;
    hinting = lib.mkDefault "full";

    defaultFonts = {
      monospace = [ "Monaspace Krypton" "MonaspiceKr Nerd Font" ];
      sansSerif = [ "Inter" ];
      serif = [ "Crimson Pro" ];
    };
  };
}
