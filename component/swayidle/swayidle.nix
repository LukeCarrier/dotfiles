{ config, pkgs, ... }:
let
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  lockCmd =
    (builtins.head (builtins.filter (e: e.event == "lock") config.services.swayidle.events)).command;
in
{
  services.swayidle = {
    enable = true;

    events = [
      {
        event = "before-sleep";
        command = lockCmd;
      }
    ];

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
