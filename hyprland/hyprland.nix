{ config, pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
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
