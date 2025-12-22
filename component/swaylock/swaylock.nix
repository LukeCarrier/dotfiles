{ desktopConfig, pkgs, ... }:
let
  swaylock = "${pkgs.swaylock}/bin/swaylock";
  lockCmd = "${swaylock} -fF";
in
{
  services.hypridle.settings.general.lock_cmd = lockCmd;

  services.swayidle.events = {
    lock = lockCmd;
  };

  programs.swaylock = {
    enable = true;
    settings = {
      image = desktopConfig.background;
    };
  };
}
