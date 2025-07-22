{ desktopConfig, ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
      preload = [
        desktopConfig.background
      ];
      wallpaper = [
        ",${desktopConfig.background}"
      ];
    };
  };
}
