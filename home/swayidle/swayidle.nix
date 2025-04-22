{ ... }:
{
  services.swayidle = {
    enable = true;

    events = [
      {
        event = "before-sleep";
        command = "loginctl lock-session";
      }
    ];

    timeouts = [
      {
        timeout = 60;
        command = "brightnessctl -sd rgb:kbd_backlight set 0";
        resumeCommand = "brightnessctl -rd rgb:kbd_backlight";
      }
      {
        timeout = 120;
        command = "loginctl lock-session";
      }
      {
        timeout = 300;
        command = "systemctl suspend-then-hibernate";
      }
    ];
  };
}
