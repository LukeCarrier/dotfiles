{ pkgs, kanshiConfig, ... }:
{
  home.packages = [ pkgs.kanshi ];

  services.kanshi = {
    enable = true;
    package = pkgs.kanshi;
    # List outputs with:
    # - Hyprland: hyprctl monitors all
    # - Niri: niri msg outputs
    settings = kanshiConfig;
  };
}
