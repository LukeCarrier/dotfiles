{ config, lib, pkgs, ... }:
let
  inherit (lib) getExe getExe';
  brightnessctl = "${getExe pkgs.brightnessctl}";
  systemctl = "${getExe' pkgs.systemd "systemctl"}";
  lockCmd = config.services.swayidle.events.lock;
in
{
  services.swayidle = {
    enable = true;

    events.before-sleep = lockCmd;

    timeouts = [
      {
        timeout = 60;
        command = "${brightnessctl} -sd rgb:kbd_backlight set 0";
        resumeCommand = "${brightnessctl} -rd rgb:kbd_backlight";
      }
      {
        timeout = 120;
        command = lockCmd;
      }
      {
        timeout = 300;
        command = "${systemctl} suspend-then-hibernate";
      }
    ];
  };
}
