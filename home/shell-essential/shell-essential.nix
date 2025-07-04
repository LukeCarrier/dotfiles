{ pkgs, ... }:
{
  home.packages =
    with pkgs; [
      btop
      dotfiles-meta
      freshfetch
      gh
      jq
      pv
      ripgrep
      watchexec
    ]
    ++ (if pkgs.stdenv.isLinux then [ pkgs.psmisc ] else []);

  home.sessionVariables = {
    DO_NOT_TRACK = "1";
  };
}
