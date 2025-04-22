{ desktopConfig, ... }:
{
  services.wpaperd = {
    enable = true;
    settings.any.path = desktopConfig.background;
  };
}
