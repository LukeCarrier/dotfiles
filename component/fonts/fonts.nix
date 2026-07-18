{ pkgs, ... }:
{
  home.packages = with pkgs; [
    crimson-pro

    fira-code
    fira-code-symbols

    font-awesome

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
    antialiasing = true;
    hinting = "full";

    defaultFonts = {
      monospace = [ "Monaspace Krypton" ];
      sansSerif = [ "Poppins" ];
      serif = [ "Crimson Pro" ];
    };
  };
}
