{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    helix
  ];

  environment.variables.EDITOR = "hx";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
