{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
in
{
  imports = [
    ../component/bolt/nixos.nix
    ../component/fwupd/nixos.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.acpid.enable = true;

  services.fwupd.extraRemotes = [ "lvfs-testing" ];

  services.power-profiles-daemon.enable = true;

}
