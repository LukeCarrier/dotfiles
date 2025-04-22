{ config, desktopConfig, ... }:
let
  lockCmd = "pidof swaylock || ${config.programs.swaylock.package}/bin/swaylock";
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
