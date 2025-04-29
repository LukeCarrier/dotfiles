{ pkgs, ... }:
{
  nix = {
    enable = true;
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # Ensure sops-install-secrets can find getconf
  # Mic92/sops-nix#890
  launchd.agents.sops-nix = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config.EnvironmentVariables.PATH = pkgs.lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
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
