{ pkgs, ... }:
{
  home.packages =
    with pkgs; [
      # Hardware introspection
      lshw
      pciutils
      usbutils

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
    ]
    ++ (if pkgs.stdenv.isLinux then [ pkgs.psmisc ] else []);

  home.sessionVariables = {
    DO_NOT_TRACK = "1";
  };
}
