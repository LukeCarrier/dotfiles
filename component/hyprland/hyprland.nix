{ pkgs, ... }:
let
  kanshictl = "${pkgs.kanshi}/bin/kanshictl";
  waybar = "${pkgs.waybar}/bin/waybar";
in {
  home.packages = with pkgs; [
    brightnessctl
    playerctl

    flameshot
    grim
    wl-clipboard
    wf-recorder
    helvum

    libnotify

    hyprpolkitagent
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    configPackages = [ pkgs.hyprland ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = "gtk";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      misc = {
        disable_hyperland_logo = true;
        disable_splash_rendering = true;
        vfr = true;
        vrr = 1;
      };
      "$mainMod" = "SUPER";
      "$groupMod" = "ALT";
      "$moveMod" = "SHIFT";
      "$menu" = "wofi --allow-images --insensitive --show drun";
      "$terminal" = "xdg-terminal";
      debug = {
        suppress_errors = true;
      };
      input = {
        touchpad = {
          clickfinger_behaviour = true;
          natural_scroll = 1;
        };
      };
      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "CLUTTER_BACKEND,wayland"
        "GDK_BACKEND,wayland,x11,*"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "NIXOS_OZONE_WL,1"
        "GDK_SCALE,1.0"
        "GDK_DPI_SCALE,1.0"
        "XCURSOR_SIZE,32"
        "TERM,wezterm"
      ];
      exec = [
        "kanshctl reload"
      ];
      exec-once = [
        waybar
      ];
      general = {
        resize_on_border = true;
        border_size = 3;
        gaps_in = 5;
        gaps_out = 7;
        "col.inactive_border" = "rgba(ccccccff)";
        "col.active_border" = "rgba(ffffffff)";
      };
      group = {
        "col.border_inactive" = "rgba(ccccccff)";
        "col.border_active" = "rgba(ffffffff)";
        groupbar = {
          enabled = true;
          height = 24;
          indicator_height = 0;
          gradients = true;
          gradient_rounding = 12;
          gradient_round_only_edges = true;
          "col.active" = "rgba(ffffffff)";
          "col.inactive" = "rgba(ccccccff)";
          font_size = 16;
          text_color = "rgb(000000)";
        };
      };
      xwayland = {
        force_zero_scaling = true;
      };
      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 0.75;
        drop_shadow = true;
        blur = {
          enabled = true;
        };
      };
      workspace = [
        "1,monitor:eDP-1"
        "2,monitor:DP-8"
        "3,monitor:DP-7"
      ];
      bind =
        [
          # Utilities
          ", print, exec, flameshot gui"
          "$mainMod, s, exec, flameshot gui"
          # Session management
          "$mainMod, 0, exec, loginctl lock-session"
          # Window/application management
          "$mainMod, w, killactive"
          "$mainMod, g, togglegroup"
          # Launcher, a la Spotlight
          "$mainMod, SPACE, exec, $menu"
          # Navigate between windows, Vi style
          "$mainMod, h, movefocus, l"
          "$mainMod, j, movefocus, d"
          "$mainMod, k, movefocus, u"
          "$mainMod, l, movefocus, r"
          # Move windows, Vi style
          "$mainMod $moveMod, h, movewindoworgroup, l"
          "$mainMod $moveMod, j, movewindoworgroup, d"
          "$mainMod $moveMod, k, movewindoworgroup, u"
          "$mainMod $moveMod, l, movewindoworgroup, r"
          # Navigate between grouped windows, Vi style
          "$mainMod $groupMod, h, changegroupactive, b"
          "$mainMod $groupMod, j, changegroupactive, f"
          "$mainMod $groupMod, k, changegroupactive, b"
          "$mainMod $groupMod, l, changegroupactive, f"
          # Shift workspace between monitors
          "$mainMod $moveMod, Tab, movecurrentworkspacetomonitor, +1"
        ]
        ++ (builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mainMod, code:1${toString i}, workspace, ${toString ws}"
              "$mainMod $moveMod, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          ) 9
        ));
      # Repeat, and bound even when locked
      # Get the key names via xev
      bindel = [
        ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioLowerVolume,exec,wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 2%-"
        ",XF86AudioRaiseVolume,exec,wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 2%+"
        ",XF86AudioPrev,exec,playerctl previous"
        ",XF86AudioPlay,exec,playerctl play-pause"
        ",xf86audioNext,exec,playerctl next"
        ",XF86MonBrightnessDown,exec,brightnessctl set 2%-"
        ",XF86MonBrightnessUp,exec,brightnessctl set +2%"
        ",XF86AudioMedia,exec,$terminal"
        # The `EC takes care of this on the Framework 13 AMD:
        # Display key sends Super+L, not XF86Display, for some reason
        # XF86RFKill is done for us
      ];
      # FIXME: this won't work outside of Peacehaven; we need to script this
      bindl = [
        ",switch:off:Lid Switch,exec,${kanshictl} switch peacehavenDockedOpen"
        ",switch:on:Lid Switch,exec,${kanshictl} switch peacehavenDockedClosed"
      ];
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 4;
      };
      windowrulev2 = [
        "opacity 1.0 override 1.0 override 1.0 override, title:(Picture-in-Picture)"
        "opacity 1.0 override 1.0 override 1.0 override, title:.*(Twitch|YouTube).*Mozilla Firefox$"
        "float, class:^(org.telegram.desktop|telegramdesktop)$, title:^(Media viewer)$"

        "float, class:^flameshot$, title:^flameshot$"
        "move 0 0, class:^flameshot$, title:^flameshot$"
        "suppressevent fullscreen, class:^flameshot$, title:^flameshot$"
        "noanim, class:^flameshot$, title:^flameshot$"
      ];
    };
  };

  programs.waybar.settings.mainBar.modules-left = [
    "hyprland/workspaces"
    "hyprland/window"
  ];
}
