{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = "loginctl lock-session";
      };
      listener = [
        {
          timeout = 60;
          on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
          on-resume = "brightnessctl -rd rgb:kbd_backlight";
        }
        {
          timeout = 120;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 300;
          # Suspend to system RAM, then awake and suspend to disk after
          # HibernateDelaySec (set elsewhere) elapses.
          on-timeout = "systemctl suspend-then-hibernate";
        }
      ];
    };
  };
}
