{ config, desktopConfig, pkgs, ... }:
let
  pidof = "${pkgs.procps}/bin/pidof";
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
  lockCmd = "${pidof} swaylock || ${swaylock}";
in {
  services.hypridle.settings.general.lock_cmd = lockCmd;

  services.swayidle.events = [
    {
      event = "lock";
      command = lockCmd;
    }
  ];

  programs.swaylock = {
    enable = true;
    settings = {
      image = desktopConfig.background;
    };
  };
}
