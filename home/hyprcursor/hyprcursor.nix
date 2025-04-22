{ desktopConfig, pkgs, ... }:
{
  home.packages = [ pkgs.hyprcursor ];

  home.sessionVariables = {
    "HYPRCURSOR_THEME" = desktopConfig.pointerCursor.name;
    "HYPRCURSOR_SIZE" = "32";
    "XCURSOR_THEME" = desktopConfig.pointerCursor.name;
  };
}
