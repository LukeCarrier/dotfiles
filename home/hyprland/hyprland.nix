{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pkgs.kanshi

    brightnessctl
    playerctl

    flameshot
    grim
    wl-clipboard
    wf-recorder
    helvum
    wofi

    mako
    libnotify

    hyprcursor
    hyprpolkitagent
    bibata-cursors

    libsecret
    seahorse
    gcr
  ];

  services.gnome-keyring = {
    enable = true;
    components = [
      "pkcs11"
      "secrets"
      "ssh"
    ];
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "menu:";
    };
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      configPackages = with pkgs; [
        gnome-keyring
        hyprland
      ];
      config.hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Settings" = "gtk";
      };
    };

    userDirs.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      package = pkgs.poppins;
      name = "Poppins";
    };
    theme = {
      package = pkgs.colloid-gtk-theme;
      name = "Colloid-Dark";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 32;
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 32;
  };

  services.kanshi = {
    enable = true;
    package = pkgs.kanshi;
    systemdTarget = "hyprland-session.target";
    settings = [
      # Laptop's own display
      {
        output.criteria = "eDP-1";
        output.mode = "2880x1920@120Hz";
        output.adaptiveSync = true;
        output.scale = 1.25;
        output.transform = null;
      }

      # My office
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

      # Michael's office
      {
        output.criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
        output.mode = "1920x1080@60Hz";
        output.adaptiveSync = false;
        output.scale = 1.0;
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
      {
        profile.name = "peacehavenSidecar";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company U32J59x HTPK602008";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            position = "768,1728";
          }
        ];
      }
      {
        profile.name = "peacehavenMichaelDocked";
        profile.outputs = [
          {
            criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            position = "1920,540";
          }
        ];
      }
    ];
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
      "$menu" = "wofi --allow-images --gtk-dark --insensitive --show drun";
      "$fileManager" = "nautilus";
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
        "TERM,wezterm"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "CLUTTER_BACKEND,wayland"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "NIXOS_OZONE_WL,1"
        "GDK_SCALE,1.5"
        "GDK_DPI_SCALE,1"
        "HYPRCURSOR_THEME,Bibata-Modern-Classic"
        "HYPRCURSOR_SIZE,32"
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "XCURSOR_SIZE,32"
      ];
      exec = [
        "kanshctl reload"
      ];
      exec-once = [
        "waybar"
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
          # Session management
          "$mainMod, 0, exec, hyprlock"
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
        ",switch:off:Lid Switch,exec,kanshictl switch peacehavenDockedOpen"
        ",switch:on:Lid Switch,exec,kanshictl switch peacehavenDockedClosed"
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

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "loginctl unlock-session";
      };
      listener = [
        {
          timeout = 60;
          on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
          on-resume = "brightnessctl -rd rgb:kbd_backlight";
        }
        {
          timeout = 120;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 300;
          # Suspend to system RAM, then awake and suspend to disk after
          # HibernateDelaySec (set elsewhere) elapses.
          on-timeout = "systemctl suspend-then-hibernate";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        monitor = "";
        path = "$HOME/Pictures/Wallpaper/London as theme park.jpg";
        blur_passes = 2;
        # I think these might be the defaults:
        # https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/
        noise = 0.0117;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };
      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$TIME"'';
          color = "rgba(200, 200, 200, 1.0)";
          font_size = 55;
          font_family = "Poppins";
          position = "-100, 70";
          halign = "right";
          valign = "bottom";
          shadow_passes = 5;
          shadow_size = 10;
        }
        # Parallel fingerprint/password unlock without pam_grosshack:
        # https://github.com/hyprwm/hyprlock/issues/258#issuecomment-2378219595
        # Seems to break rendering of the UI?
        # {
        #   monitor = "";
        #   text = "cmd[update:0:0] until fprintd-verify -f right-index-finger; do :; done; pkill -USR1 hyprlock";
        # }
      ];
      input-field = {
        monitor = "";
        size = "200, 50";
        outline_thickness = 4;
        dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
        outer_color = "rgb(151515)";
        inner_color = "rgb(FFFFFF)";
        font_color = "rgb(10, 10, 10)";
        fade_on_empty = true;
        fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
        placeholder_text = "Password…";
        hide_input = false;
        rounding = -1; # -1 means complete rounding (circle/oval)
        check_color = "rgb(204, 136, 34)";
        fail_color = "rgb(204, 34, 34)"; # if authentication failed, changes outer_color and fail message color
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
        fail_transition = 300; # transition time in ms between normal outer_color and fail_color
        capslock_color = -1;
        numlock_color = -1;
        bothlock_color = -1; # when both locks are active. -1 means don't change outer color (same for above)
        invert_numlock = false; # change color if numlock is off
        swap_font_color = false; # see below
        position = "0, -20";
        halign = "center";
        valign = "center";
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
          on-click = "helvum";
          format = "🔉 {volume}%";
          format-muted = "🔇";
        };
        bluetooth = {
          on-click = "blueman-manager";
        };
        network = {
          on-click = "nm-connection-editor";
          tooltip-format = ''
            <tt>Interface: {ifname}</tt>
            <tt>Primary IP: {ipaddr}</tt>
            <tt>Gateway: {gwaddr}</tt>
          '';
          format-ethernet = "🌐 {ifname}";
          format-wifi = "🛜 {essid}";
          tooltip-fprmat-wifi = ''
            <tt>eSSID: {essid}</tt>
            <tt>Frequency: {frequency}</tt>
            <tt>Interface: {ifname}</tt>
            <tt>Primary IP: {ipaddr}</tt>
            <tt>Gateway: {gwaddr}</tt>
            <tt>Signal strength: {signalStrength}</tt>
            <tt>Signal strength (dBm): {signalStrengthD}</tt>
          '';
          format-linked = "🖇️ {ifname}";
          format-disconnected = "😱";
          tooltip-format-disconnected = "No network connection";
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
        "~/Pictures/Wallpaper/Monochromatic mountains.jpg"
      ];
      wallpaper = [
        ",~/Pictures/Wallpaper/Monochromatic mountains.jpg"
      ];
    };
  };

  services.mako = {
    enable = true;
    borderColor = "#ffffff";
    borderRadius = 8;
    borderSize = 3;
    groupBy = "app-name";
    font = "Poppins 12";
    backgroundColor = "#000000bf";
    textColor = "#ffffff";
  };
}
