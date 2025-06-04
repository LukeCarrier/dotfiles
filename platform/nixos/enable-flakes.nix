{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    helix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
