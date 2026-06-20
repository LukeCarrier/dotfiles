{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
  loginctl = getExe pkgs.systemd;
  systemctl = getExe pkgs.systemd;
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = "${loginctl} lock-session";
      };
      listener = [
        {
          timeout = 120;
          on-timeout = "${loginctl} lock-session";
        }
        {
          timeout = 300;
          # Suspend to system RAM, then awake and suspend to disk after
          # HibernateDelaySec (set elsewhere) elapses.
          on-timeout = "${systemctl} suspend-then-hibernate";
        }
      ];
    };
  };
}
