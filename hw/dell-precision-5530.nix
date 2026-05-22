{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
in
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.acpid.enable = true;

  services.fwupd = {
    enable = true;
    extraRemotes = [ "lvfs-testing" ];
  };

  services.power-profiles-daemon.enable = true;

  services.hardware.bolt.enable = true;
}
