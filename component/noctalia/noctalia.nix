{
  config,
  ...
}:
let
  fontFamily = builtins.elemAt config.fonts.fontconfig.defaultFonts.sansSerif 0;
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
          transparency_mode = "soft";
        };
      };

      theme = {
        mode = "dark";
        source = "wallpaper";
        custom_palette = "Ashell";
      };

      notification.enable_daemon = true;

      system.monitor.enabled = true;

      calendar.enabled = true;

      location.address = "London";

      nightlight.enabled = true;

      hot_corners = {
        enabled = true;
        top_right.action = "launcher";
      };

      dock = {
        enabled = true;
        background_opacity = 0.35;
        launcher_position = "start";
        reserve_space = false;
        shadow = false;
        smart_auto_hide = true;
      };

      lockscreen_widgets = {
        enabled = false;
        schema_version = 2;
        widget_order = [ "lockscreen-login-box@eDP-1" ];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
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

          settings = {
            background_color = "surface_variant";
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
        };
      };

      wallpaper = {
        directory = "/home/lukecarrier/Pictures/Wallpaper";
        transition = [ "disc" ];
        transition_on_startup = true;
        automation.enabled = true;
        default.path = "/home/lukecarrier/Pictures/Wallpaper/Red Panda (Unknown via Flickr).jpg";
        last.path = "/home/lukecarrier/Pictures/Wallpaper/Red Panda (Unknown via Flickr).jpg";
        monitors."eDP-1".path = "/home/lukecarrier/Pictures/Wallpaper/Red Panda (Unknown via Flickr).jpg";
      };

      bar.main = {
        position = "top";
        background_opacity = 0.8;
        start = [ "workspaces" ];
        center = [
          "privacy"
          "cpu"
          "memory"
          "temperature"
          "download"
          "upload"
          "media"
        ];
        end = [
          "clock"
          "tardy"
          "settings"
          "tray"
        ];
      };

      widget = {
        workspaces = {
          focused_color = "primary";
          occupied_color = "secondary";
          empty_color = "secondary";
          focused_output_only = true;
          label_source = "name";
          max_label_chars = 20;
        };

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

        tardy.type = "lukecarrier/tardy:bar";
      };
    };
  };

  xdg.dataFile = {
    "noctalia/plugins/tardy/plugin.toml".source = ./plugins/tardy/plugin.toml;
    "noctalia/plugins/tardy/service.luau".source = ./plugins/tardy/service.luau;
    "noctalia/plugins/tardy/bar.luau".source = ./plugins/tardy/bar.luau;
  };
}
