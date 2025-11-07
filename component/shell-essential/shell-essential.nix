{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # System management
      btop
      freshfetch
      pv
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

  home.sessionVariables = {
    DO_NOT_TRACK = "1";
  };
}
