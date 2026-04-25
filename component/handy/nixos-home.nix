{ config, lib, pkgs, ... }:
let
  handyExe = lib.getExe pkgs.handy;
in
{
  home.packages = with pkgs; [
    handy
    wtype
  ];

  wayland.windowManager.hyprland.settings.bind = [
    "SUPER, t, exec, ${handyExe} --toggle-transcription"
  ];

  programs.niri.settings.binds =
    with config.lib.niri.actions;
    {
      "Super+T".action = spawn [
        handyExe
        "--toggle-transcription"
      ];
    };
}
