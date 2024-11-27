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
      "$terminal" = "xterm";
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
        "waybar &"
        "$terminal"
      ];
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod, SPACE, exec, $menu"
        "$mainMod, w, exec, $menu"
      ];
      input = {
        touchpad = {
          natural_scroll = 1;
        };
      };
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
    };
  };

  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: "Arimo Nerd Font", "Font Awesome 6 Free";
        font-size: 10px;
      }
    '';
  };

  services.gnome-keyring.enable = true;
}
