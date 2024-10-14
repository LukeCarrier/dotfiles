{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    wf-recorder
    kanshi
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

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$menu" = "wofi --allow-images --show drun";
      "$fileManager" = "nautilus";
      "$terminal" = "xterm";
      monitor = [
        "eDP-1, 2880x1920@120, 0x0, 1.5"
      ];
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
