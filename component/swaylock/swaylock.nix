{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
  swaylock = "${getExe pkgs.swaylock}";
  lockCmd = "${swaylock} -fF";
in
{
  services.hypridle.settings.general.lock_cmd = lockCmd;

  services.swayidle.events = {
    lock = lockCmd;
  };

  programs.swaylock = {
    enable = true;
    settings.color = "000000";
  };
}
