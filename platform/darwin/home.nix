{ pkgs, ... }:
{
  targets.darwin.defaults = {
    "com.apple.dock" = {
      autohide = true;
      show-recents = false;
      recent-apps = [ ];
      minimize-to-application = true;
    };
  };

  home.packages =
    (with pkgs; [
      csvlens
      ripgrep
      tv

      dotfiles-meta
    ])
    ++ (with pkgs.unixtools; [
      watch
    ]);
}
