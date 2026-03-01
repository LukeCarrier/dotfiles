{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # System management
      btop
      freshfetch
      pv
      unixtools.watch
      watchexec

      # Development tools
      dotfiles-meta
      gh
      jq
      ripgrep
      tree
    ]
    ++ (
      if pkgs.stdenv.isLinux then
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
