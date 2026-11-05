{
  config,
  ...
}:
let
  fontFamily = builtins.elemAt config.fonts.fontconfig.defaultFonts.sansSerif 0;

  loginBoxSettings = {
    background_color = "surface_container";
    background_opacity = 0.88;
    background_radius = 12.0;
    center_password_text = false;
    input_opacity = 1.0;
    input_radius = 6.0;
    layout = "regular";
    show_caps_lock = true;
    show_keyboard_layout = true;
    show_login_button = true;
    show_media = true;
    show_password_reveal = true;
    show_session_buttons = true;
    show_unlock_hint = true;
    show_weather = true;
  };
in
{
  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    customPalettes.Ashell = {
      dark = {
        mPrimary = "#7aa2f7";
        mOnPrimary = "#1a1b26";
        mSecondary = "#0c0d14";
        mOnSecondary = "#a9b1d6";
        mTertiary = "#9ece6a";
        mOnTertiary = "#1a1b26";
        mError = "#f7768e";
        mOnError = "#1a1b26";
        mSurface = "#1a1b26";
        mOnSurface = "#a9b1d6";
        mSurfaceVariant = "#24273a";
        mOnSurfaceVariant = "#a9b1d6";
        mOutline = "#414868";
        mShadow = "#0c0d14";
        mHover = "#24273a";
        mOnHover = "#a9b1d6";

        terminal = {
          background = "#1a1b26";
          foreground = "#a9b1d6";
          cursor = "#c0caf5";
          cursorText = "#1a1b26";
          selectionBg = "#283457";
          selectionFg = "#c0caf5";
          normal = {
            black = "#15161e";
            red = "#f7768e";
            green = "#9ece6a";
            yellow = "#e0af68";
            blue = "#7aa2f7";
            magenta = "#bb9af7";
            cyan = "#7dcfff";
            white = "#a9b1d6";
          };
          bright = {
            black = "#414868";
            red = "#f7768e";
            green = "#9ece6a";
            yellow = "#e0af68";
            blue = "#7aa2f7";
            magenta = "#bb9af7";
            cyan = "#7dcfff";
            white = "#c0caf5";
          };
        };
      };
    };

    settings = {
      plugins.enabled = [ "lukecarrier/tardy" ];

      shell = {
        font_family = fontFamily;
        niri_overview_type_to_launch_enabled = true;
        screen_time_enabled = true;
        settings_window_translucent = true;
        panel = {
          floating_layer = "top";
          transparency_mode = "glass";
        };
        privacy.mic_filter_regex = "handy";
      };

      theme = {
        mode = "dark";
        source = "wallpaper";
        builtin = "Tokyo-Night";
        community_palette = "ADW";
        custom_palette = "Ashell";
        wallpaper_scheme = "m3-content";
      };

      notification.enable_daemon = true;

      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
        allow_empty_password = true;
        transition = [ "zoom" ];
      };

      idle.behavior.lock = {
        action = "lock";
        enabled = true;
        timeout = 120;
      };

      system.monitor.enabled = true;

      calendar.enabled = true;

      control_center = {
        sidebar = "full";
        sidebar_section = "none";
      };

      location.address = "London";

      nightlight.enabled = true;

      hot_corners = {
        enabled = true;
        top_right.action = "launcher";
      };

      dock = {
        enabled = false;
        background_opacity = 0.35;
        position = "left";
        launcher_position = "start";
        reserve_space = false;
        shadow = true;
        smart_auto_hide = true;
      };

      lockscreen_widgets = {
        enabled = true;
        schema_version = 2;
        widget_order = [
          "lockscreen-login-box@DP-1"
          "lockscreen-login-box@DP-2"
          "lockscreen-login-box@eDP-1"
        ];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget."lockscreen-login-box@DP-1" = {
          box_height = 196.0;
          box_width = 810.0;
          cx = 1536.0;
          cy = 878.0;
          output = "DP-1";
          placement_height = 1728.0;
          placement_width = 3072.0;
          rotation = 0.0;
          type = "login_box";

          settings = loginBoxSettings;
        };

        widget."lockscreen-login-box@DP-2" = {
          box_height = 196.0;
          box_width = 810.0;
          cx = 1536.0;
          cy = 880.0;
          output = "DP-2";
          placement_height = 1728.0;
          placement_width = 3072.0;
          rotation = 0.0;
          type = "login_box";

          settings = loginBoxSettings;
        };

        widget."lockscreen-login-box@eDP-1" = {
          box_height = 196.0;
          box_width = 810.0;
          cx = 960.0;
          cy = 1018.0;
          output = "eDP-1";
          placement_height = 1200.0;
          placement_width = 1920.0;
          rotation = 0.0;
          type = "login_box";

          settings = loginBoxSettings;
        };
      };

      wallpaper = {
        directory = "/home/lukecarrier/Pictures/Wallpaper";
        transition = [ "disc" ];
        transition_on_startup = true;
        automation.enabled = true;
        default.path = "/home/lukecarrier/Pictures/Wallpaper/Tree-lined lake (Petr Ganaj).jpg";
        last.path = "/home/lukecarrier/Pictures/Wallpaper/Tree-lined lake (Petr Ganaj).jpg";
        monitors."DP-1".path = "/home/lukecarrier/Pictures/Wallpaper/Squirrel (Adrian Westra).jpg";
        monitors."DP-2".path = "/home/lukecarrier/Pictures/Wallpaper/Squirrel (Adrian Westra).jpg";
        monitors."eDP-1".path = "/home/lukecarrier/Pictures/Wallpaper/Tree-lined lake (Petr Ganaj).jpg";
      };

      bar.main = {
        position = "top";
        background_opacity = 0.8;
        capsule = true;
        contact_shadow = true;
        margin_ends = 4;
        start = [ "workspaces" ];
        center = [
          "privacy"
          "control-center"
          "group:g2"
          "group:g1"
        ];
        end = [
          "clock"
          "tardy"
          "group:g4"
        ];

        capsule_group = [
          {
            id = "g2";
            enabled = true;
            accordion = false;
            accordion_direction = "end";
            border_width = 1.0;
            fill = "surface_container";
            members = [
              "battery"
              "cpu"
              "memory"
              "temperature"
              "network_rx"
              "network_tx"
            ];
            opacity = 1.0;
            padding = 6.0;
          }
          {
            id = "g1";
            enabled = true;
            accordion = false;
            accordion_direction = "end";
            border_width = 1.0;
            fill = "surface_container";
            members = [
              "media"
              "audio_visualizer"
            ];
            opacity = 1.0;
            padding = 6.0;
          }
          {
            id = "g4";
            enabled = true;
            accordion = false;
            accordion_direction = "end";
            border_width = 1.0;
            fill = "surface_container";
            members = [ "tray" ];
            opacity = 1.0;
            padding = 6.0;
          }
        ];
      };

      widget = {
        workspaces = {
          focused_color = "primary";
          occupied_color = "secondary";
          empty_color = "secondary";
          focused_output_only = true;
          label_source = "name";
          labels_only_when_occupied = true;
          max_label_chars = 20;
        };

        battery = {
          display_mode = "graphic";
          label_content = "time";
        };

        clock = {
          capsule = true;
          format = "{:%Y-%m-%d %H:%M}";
        };

        "control-center" = {
          capsule = true;
          glyph = "adjustments";
          actions.right = "session lock";
        };

        privacy.capsule = true;

        cpu = {
          type = "sysmon";
          stat = "cpu_usage";
        };

        memory = {
          type = "sysmon";
          stat = "ram_pct";
        };

        temperature = {
          type = "sysmon";
          stat = "cpu_temp";
        };

        download = {
          type = "sysmon";
          stat = "net_rx";
          network_speed_compact = true;
        };

        upload = {
          type = "sysmon";
          stat = "net_tx";
          network_speed_compact = true;
        };

        tardy = {
          type = "lukecarrier/tardy:bar";
          capsule = true;
          actions.left = "exec tardy open";
        };
      };
    };
  };

  xdg.dataFile = {
    "noctalia/plugins/tardy/plugin.toml".source = ./plugins/tardy/plugin.toml;
    "noctalia/plugins/tardy/service.luau".source = ./plugins/tardy/service.luau;
    "noctalia/plugins/tardy/bar.luau".source = ./plugins/tardy/bar.luau;
  };
}
