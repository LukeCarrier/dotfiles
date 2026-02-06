{ pkgs, ... }:
{
  nix = {
    enable = true;
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

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
