{ pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  home.packages =
    with pkgs;
    [
      # System management
      btop
      coreutils-full
      freshfetch
      pv
      unixtools.watch

      # Development tools
      dotfiles-meta
      jq
      ripgrep
      tree
    ]
    ++ (
      if isLinux then
        with pkgs;
        [
          # Hardware introspection
          lshw
          pciutils
          usbutils
          psmisc
        ]
      else
        [ ]
    );

  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
    config = {
      theme = "base16-256";
    };
  };

  home.sessionVariables = {
    DO_NOT_TRACK = "1";
  };
}
