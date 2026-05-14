{ desktopConfig, ... }:
{
  services.wpaperd = {
    enable = true;
    settings.any = {
      duration = "1h";
      path = desktopConfig.background;
    };
  };
}
