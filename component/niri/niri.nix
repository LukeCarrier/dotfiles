{ config, lib, pkgs, ... }:
let
  kanshictl = "${pkgs.kanshi}/bin/kanshictl";
  niri = "${config.programs.niri.package}/bin/niri";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  waybar = "${pkgs.waybar}/bin/waybar";
  xwaylandSatellite = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
  xwaylandSatelliteDisplay = ":1";
  workspaceRename = pkgs.writeShellScriptBin "niri-workspace-rename" ''
    niri="${niri}"
    wofi="${pkgs.wofi}/bin/wofi"
    name="$("$wofi" --dmenu --lines 1 </dev/null)"
    if [[ "$name" == "" ]]; then
      "$niri" msg action unset-workspace-name
    else
      "$niri" msg action set-workspace-name "$name"
    fi
  '';
in {
  home.packages = (with pkgs; [
    brightnessctl
    playerctl

    wl-clipboard
    wf-recorder
    helvum

    mako
    libnotify
  ]);

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.niri = {
      default = [ "gtk" "gnome" ];
      "org.freedesktop.impl.portal.Access" = "gtk";
      "org.freedesktop.impl.portal.Notification" = "gtk";
      "org.freedesktop.impl.portal.Screencast" = "gnome";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      "org.freedesktop.impl.portal.Settings" = "gtk";
    };
  };

  # sodiboo/niri-flake#509
  systemd.user.services.niri-flake-polkit = {
    after = {
      "graphical-session.target" = true;
    };
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
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
        warp-mouse-to-focus.enable = true;
        focus-follows-mouse = {};
      };
      spawn-at-startup = [
        { command = [ systemctl "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" ]; }
        { command = [ waybar ]; }
        { command = [ xwaylandSatellite xwaylandSatelliteDisplay ]; }
        { command = [ kanshictl "reload" ]; }
      ];
      environment = {
        XDG_SESSION_DESKTOP = "niri";
        DISPLAY = xwaylandSatelliteDisplay;
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11,*";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        NIXOS_OZONE_WL = "1";
        GDK_SCALE = "1.0";
        GDK_DPI_SCALE = "1.0";
        XCURSOR_SIZE = "32";
        TERM = "wezterm";
      };
      binds =
        let
          mainMod = "Super";
          moveMod = "Shift";
          spaceMod = "Alt";
          terminal = "xdg-terminal";
        in with config.lib.niri.actions; ({
          # Utilities
          "Print".action = screenshot;
          "${mainMod}+S".action = screenshot;
          "XF86AudioMute".action = spawn [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
          "XF86AudioLowerVolume".action = spawn [ "wpctl" "set-volume" "-l" "1.4" "@DEFAULT_AUDIO_SINK@" "2%-" ];
          "XF86AudioRaiseVolume".action = spawn [ "wpctl" "set-volume" "-l" "1.4" "@DEFAULT_AUDIO_SINK@" "2%+" ];
          "XF86AudioPrev".action = spawn [ "playerctl" "previous" ];
          "XF86AudioPlay".action = spawn [ "playerctl" "play-pause" ];
          "xf86audioNext".action = spawn [ "playerctl" "next" ];
          "XF86MonBrightnessDown".action = spawn [ "brightnessctl" "set" "2%-" ];
          "XF86MonBrightnessUp".action = spawn [ "brightnessctl" "set" "+2%" ];
          "XF86AudioMedia".action = spawn [ terminal ];
          # The `EC takes care of this on the Framework 13 AMD:
          # Display key sends Super+L, not XF86Display, for some reason
          # XF86RFKill is done for us
          # Session management
          "${mainMod}+0".action = spawn [ "loginctl" "lock-session" ];
          # Window/application management
          "${mainMod}+W".action = close-window;
          "${mainMod}+G".action = toggle-column-tabbed-display;
          # Launcher, a la Spotlight
          "${mainMod}+Space".action = spawn [ "wofi" "--allow-images" "--insensitive" "--show" "drun" ];
          # Navigate between windows and columns, Vi style
          # Window commands navigate tabs, no need for separate bindings
          "${mainMod}+Tab".action = focus-window-previous;
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
          # Shift column between monitors
          "${mainMod}+${moveMod}+Tab".action = move-column-to-monitor-next;
          # Shift workspace between monitors
          "${mainMod}+${spaceMod}+${moveMod}+Tab".action = move-workspace-to-monitor-next;
          # Space management
          "${mainMod}+${spaceMod}+${moveMod}+J".action = move-workspace-down;
          "${mainMod}+${spaceMod}+${moveMod}+K".action = move-workspace-up;
          "${mainMod}+R".action = spawn [ "${workspaceRename}/bin/niri-workspace-rename" ];
          # Space navigation
          "${mainMod}+${spaceMod}+Space".action = toggle-overview;
          "${mainMod}+${spaceMod}+Tab".action = focus-workspace-previous;
          "${mainMod}+${spaceMod}+J".action = focus-workspace-down;
          "${mainMod}+${spaceMod}+K".action = focus-workspace-up;
        })
        // lib.attrsets.listToAttrs (builtins.concatMap (i: with config.lib.niri.actions; [
          {
            name = "${mainMod}+${toString i}";
            value.action = focus-workspace i;
          }
          # FIXME: use the action directly once sodiboo/niri-flake#1018 is fixed.
          {
            name = "${mainMod}+${moveMod}+${toString i}";
            value.action = spawn [ niri "msg" "action" "move-column-to-workspace" (toString i) ];
          }
        ]) (lib.range 1 9));
      switch-events = with config.lib.niri.actions; {
        lid-close.action = spawn [ "kanshictl" "switch" "peacehavenDockedClosed" ];
        lid-open.action = spawn [ "kanshictl" "switch" "peacehavenDockedOpen" ];
      };
      prefer-no-csd = true;
      layout = {
        always-center-single-column = true;
        gaps = 12;
        border.enable = false;
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#ffffff";
        };
        shadow.enable = true;
        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          position = "top";
        };
      };
      layer-rules = [
        {
          matches = [
            { namespace = "^notifications$"; }
          ];
          block-out-from = "screencast";
        }
      ];
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
        # Messaging clients
        {
          matches = [
            { app-id = "^org.mozilla.Thunderbird$"; }
            { app-id = "^org.signal.Signal$"; }
            { app-id = "^org.telegram.desktop$"; }
            { app-id = "^discord$"; }
            { app-id = "^Slack$"; }
            { title = "^WhatsApp Web$"; }
          ];
          block-out-from = "screencast";
        }
        # Password managers
        {
          matches = [
            { app-id = "^Bitwarden$"; }
          ];
          block-out-from = "screencast";
        }
        # PiP overlays
        {
          matches = [
            { title = "^Picture-in-Picture$"; }
          ];
          open-floating = true;
        }
      ];
    };
  };

  programs.waybar.settings.mainBar = {
    modules-left = [
      "niri/workspaces"
      "niri/window"
    ];

    "niri/workspaces".format = "{index}:{value}";
  };
}
