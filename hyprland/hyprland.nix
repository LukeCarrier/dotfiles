{ config, pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
    playerctl

    wl-clipboard
    wf-recorder
    pkgs-unstable.kanshi
    mako
    grim
    slurp
    wofi

    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    mplus-outline-fonts.githubRelease
    nerdfonts
    noto-fonts
    noto-fonts-emoji
    proggyfonts
  ];

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;
    font = {
      package = pkgs.poppins;
      name = "Poppins";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.gnome.adwaita-icon-theme;
    name = "Adwaita";
  };

  services.kanshi = {
    enable = true;
    package = pkgs-unstable.kanshi;
    systemdTarget = "hyprland-session.target";
    settings = [
      {
        output.criteria = "eDP-1";
        output.mode = "2880x1920@120Hz";
        output.adaptiveSync = true;
        output.scale = 1.25;
        output.transform = null;
      }
      {
        output.criteria = "Samsung Electric Company U32J59x HTPK702789";
        output.mode = "3840x2160@60Hz";
        output.adaptiveSync = false;
        output.scale = 1.25;
        output.transform = null;
      }
      {
        output.criteria = "Samsung Electric Company U32J59x HTPK602008";
        output.mode = "3840x2160@30Hz";
        output.adaptiveSync = false;
        output.scale = 1.25;
        output.transform = null;
      }
      {
        profile.name = "mobile";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
        ];
      }
      {
        profile.name = "peacehavenDockedClosed";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Samsung Electric Company U32J59x HTPK702789";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Samsung Electric Company U32J59x HTPK602008";
            status = "enable";
            position = "3072,0";
          }
        ];
      }
      {
        profile.name = "peacehavenDockedOpen";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company U32J59x HTPK702789";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Samsung Electric Company U32J59x HTPK602008";
            status = "enable";
            position = "3072,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            position = "4224,1728";
          }
        ];
      }
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$menu" = "wofi --allow-images --show drun";
      "$fileManager" = "nautilus";
      "$terminal" = "alacritty";
      input = {
        touchpad = {
          natural_scroll = 1;
        };
      };
      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "CLUTTER_BACKEND,wayland"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "NIXOS_OZONE_WL,1"
      ];
      exec-once = [
        "waybar"
      ];
      "$mainMod" = "SUPER";
      workspace = [
        "1,monitor:eDP-1"
        "2,monitor:DP-8"
        "3,monitor:DP-7"
      ];
      bind =
          [
            "$mainMod, Q, exec, $terminal"
            "$mainMod, SPACE, exec, $menu"
            "$mainMod, w, exec, $menu"
          ]
          ++ (
            builtins.concatLists (builtins.genList (i:
              let ws = i + 1;
              in [
                "$mainMod, code:1${toString i}, workspace, ${toString ws}"
                "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
          );
      # Repeat, and bound even when locked
      # Get the key names via xev
      bindel = [
        ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioLowerVolume,exec,wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 2%-"
        ",XF86AudioRaiseVolume,exec,wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 2%+"
        ",XF86AudioPrev,exec,playerctl previous"
        ",XF86AudioPlay,exec,playerctl play-pause"
        ",xf86audioNext,exec,playerctl next"
        ",XF86MonBrightnessDown,exec,brightnessctl set -2%"
        ",XF86MonBrightnessUp,exec,brightnessctl set +2%"
        ",XF86AudioMedia,exec,$terminal"
        # The `EC takes care of this on the Framework 13 AMD:
        # Display key sends Super+L, not XF86Display, for some reason
        # XF86RFKill is done for us
      ];
      # FIXME: this won't work outside of Peacehaven; we need to script this
      bindl = [
        ",switch:off:Lid Switch,exec,kanshictl switch peacehavenDockedOpen"
        ",switch:on:Lid Switch,exec,kanshictl switch peacehavenDockedClosed"
      ];
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 4;
      };
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [
          "clock"
          "privacy"
          "mpris"
        ];
        modules-right = [
          "battery"
          "power-profiles-daemon"
          "wireplumber"
          "bluetooth"
          "network"
          "idle_inhibitor"
          "tray"
        ];

        clock = {
          format = "{:%Y-%m-%d %H:%M (%Z)}";
          tooltip-format = ''
            <tt>{tz_list}</tt>
            <tt></tt>
            <tt>{calendar}</tt>
          '';
          timezones = [
            "Europe/London"
            "Etc/UTC"
            "Europe/Warsaw"
            "America/Miami"
            "Asia/New_Delhi"
          ];
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };
        privacy = {
          icon-size = 15;
        };
        battery = {
          format = "{icon} {capacity}%";
          format-icons = {
            full = "";
            good = "";
            half = "";
            warning = "";
            critical = "";
          };
          full_at = 80;
          states = {
            full = 100;
            good = 80;
            half = 60;
            warning = 40;
            critical = 20;
          };
        };
        power-profiles-daemon = {
          format-icons = {
            default = "🐾";
            performance = "🦄";
            balanced = "🦡";
            power-saver = "🦥";
          };
        };
        wireplumber = {
          format = "🔉 {volume}%";
          format-muted = "🔇";
        };
        bluetooth = {};
        network = {
          format-ethernet = "🌐 {ifname}";
          format-wifi = "🛜 {essid}";
          format-linked = "🖇️ {ifname}";
          format-disconnected = "😱";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "☕️";
            deactivated = "🍻";
          };
        };
      };
    };
    style = builtins.readFile ./waybar.css;
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
      preload = [
        "~/Pictures/Wallpaper/Mountains under cloudy sky (Simon Berger).jpg"
      ];
      wallpaper = [
        ",~/Pictures/Wallpaper/Mountains under cloudy sky (Simon Berger).jpg"
      ];
    };
  };

  services.gnome-keyring.enable = true;
}
