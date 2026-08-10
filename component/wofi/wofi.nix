{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  launcher = [
    (getExe pkgs.wofi)
    "--allow-images"
    "--insensitive"
    "--show"
    "drun"
  ];
  workspacePicker = [
    (getExe pkgs.wofi)
    "--dmenu"
    "--lines"
    "1"
  ];
in
{
  home.packages = [ pkgs.wofi ];

  programs.niri.launcher = launcher;
  programs.niri.workspacePicker = workspacePicker;

  wayland.windowManager.hyprland.settings = {
    "$menu" = "wofi --allow-images --insensitive --show drun";
    bind = [ "$mainMod, SPACE, exec, $menu" ];
  };

  home.file."${config.xdg.configHome}/wofi/style.css".text = ''
    @define-color default-fg #2d3e4e;
    @define-color invert-fg #ffffff;
    @define-color alert #eb4d4b;

    * {
      font-family: "${builtins.elemAt config.fonts.fontconfig.defaultFonts.sansSerif 0}", "Font Awesome 6 Free";
    }

    window, #outer-box {
      background-color: transparent;
      margin: 5px;
    }

    #input, #inner-box {
      margin: 0 5px;
      background-color: @default-fg;
    }

    #input {
      font-size: 3em;
    }

    .entry, .entry#selected, .entry#unselected {
      border-radius: 0;
    }
  '';
}