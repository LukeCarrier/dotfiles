{ config, lib, pkgs, ... }:
let
  pointerCursor = config.home.pointerCursor.name;
  workspaceRename = pkgs.writeShellScriptBin "niri-workspace-rename" ''
    niri="${pkgs.niri}/bin/niri"
    wofi="${pkgs.wofi}/bin/wofi"
    "$niri" msg action set-workspace-name "$("$wofi" --dmenu --lines 1 </dev/null)"
  '';
in {
  home.packages = with pkgs; [
    brightnessctl
    playerctl

    wl-clipboard
    wf-recorder
    helvum
    wofi

    mako
    libnotify
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.niri = {
      default = [ "gtk" "gnome" ];
      "org.freedesktop.impl.portal.Settings" = "gtk";
    };
  };

  programs.niri = {
    enable = true;
    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
        };
        touchpad = {
          click-method = "clickfinger";
          natural-scroll = true;
          tap = true;
        };
        warp-mouse-to-focus = true;
        focus-follows-mouse = {};
      };
      spawn-at-startup = [
        { command = [ "waybar" ]; }
        { command = [ "xwayland-satellite" ]; }
        { command = [ "kanshictl" "reload" ]; }
      ];
      environment = {
        XDG_SESSION_DESKTOP = "niri";
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11,*";
        QT_QPA_PLATFORM = "wayland;xcb";
        NIXOS_OZONE_WL = "1";
        GDK_SCALE = "1.5";
        GDK_DPI_SCALE = "1";
        XCURSOR_THEME = pointerCursor;
        XCURSOR_SIZE = "32";
        TERM = "wezterm";
      };
      binds =
        let
          mainMod = "Super";
          moveMod = "Shift";
          terminal = "xdg-terminal";
        in with config.lib.niri.actions; ({
          # Utilities
          "Print".action = screenshot;
          "${mainMod}+S".action = screenshot;
          "XF86AudioMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
          "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "-l" "1.4" "@DEFAULT_AUDIO_SINK@" "2%-" ];
          "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "-l" "1.4" "@DEFAULT_AUDIO_SINK@" "2%+" ];
          "XF86AudioPrev".action.spawn = [ "playerctl" "previous" ];
          "XF86AudioPlay".action.spawn = [ "playerctl" "play-pause" ];
          "xf86audioNext".action.spawn = [ "playerctl" "next" ];
          "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "2%-" ];
          "XF86MonBrightnessUp".action.spawn = [ "brightnessctl" "set" "+2%" ];
          "XF86AudioMedia".action.spawn = [ terminal ];
          # The `EC takes care of this on the Framework 13 AMD:
          # Display key sends Super+L, not XF86Display, for some reason
          # XF86RFKill is done for us
          # Session management
          "${mainMod}+0".action.spawn = "hyprlock";
          # Window/appliucation management
          "${mainMod}+W".action = close-window;
          "${mainMod}+G".action = toggle-column-tabbed-display;
          # Launcher, a la Spotlight
          "${mainMod}+Space".action.spawn = [ "wofi" "--allow-images" "--gtk-dark" "--insensitive" "--show" "drun" ];
          # Navigate between windows and columns, Vi style
          # Window commands navigate tabs, no need for separate bindings
          "${mainMod}+H".action = focus-column-left;
          "${mainMod}+J".action = focus-window-down;
          "${mainMod}+K".action = focus-window-up;
          "${mainMod}+L".action = focus-column-right;
          # Move windows, Vi style
          "${mainMod}+${moveMod}+H".action = move-column-left;
          "${mainMod}+${moveMod}+J".action = move-window-down;
          "${mainMod}+${moveMod}+K".action = move-window-up;
          "${mainMod}+${moveMod}+L".action = move-column-right;
          # Group windows
          "${mainMod}+${moveMod}+BracketLeft".action = consume-or-expel-window-left;
          "${mainMod}+${moveMod}+BracketRight".action = consume-or-expel-window-right;
          # Shift workspace between monitors
          "${mainMod}+${moveMod}+Tab".action = move-workspace-to-monitor-next;
          # Space management
          "${mainMod}+R".action.spawn = [ "${workspaceRename}/bin/niri-workspace-rename" ];
        })
        // lib.attrsets.listToAttrs (builtins.concatMap (i: with config.lib.niri.actions; [
          {
            name = "${mainMod}+${toString i}";
            value.action = focus-workspace i;
          }
          {
            name = "${mainMod}+${moveMod}+${toString i}";
            value.action = move-window-to-workspace i;
          }
        ]) (lib.range 1 9));
      switch-events = {
        lid-close.action.spawn = [ "kanshictl" "switch" "peacehavenDockedClosed" ];
        lid-open.action.spawn = [ "kanshictl" "switch" "peacehavenDockedOpen" ];
      };
      prefer-no-csd = true;
      layout = {
        always-center-single-column = true;
        gaps = 6;
        border.enable = false;
        focus-ring = {
          enable = true;
          active.color = "#ffffff";
        };
        shadow.enable = true;
        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          position = "top";
        };
      };
      window-rules = [
        {
          clip-to-geometry = true;
          draw-border-with-background = false;
          geometry-corner-radius = {
            top-left = 8.0;
            top-right = 8.0;
            bottom-left = 8.0;
            bottom-right = 8.0;
          };
        }
      ];
    };
  };

  programs.waybar.settings.mainBar.modules-left = [
    "niri/workspaces"
    "niri/window"
  ];
}
