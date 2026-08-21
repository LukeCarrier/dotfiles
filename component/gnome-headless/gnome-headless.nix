{ config, desktopConfig, pkgs, ... }:
{
  home.packages = with pkgs; [
    libsecret
    seahorse
    gcr

    bibata-cursors
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
    mimeApps = {
      enable = true;
      defaultApplications =
        let
          app = "org.gnome.Nautilus.desktop";
        in
        {
          "inode/directory" = app;
          "x-scheme-handler/file" = app;
          "application/x-7z-compressed" = app;
          "application/x-7z-compressed-tar" = app;
          "application/x-bzip" = app;
          "application/x-bzip-compressed-tar" = app;
          "application/x-bzip2-compressed-tar" = app;
          "application/x-compressed-tar" = app;
          "application/x-cpio" = app;
          "application/x-gzip" = app;
          "application/x-lha" = app;
          "application/x-lzip-compressed-tar" = app;
          "application/x-lzma-compressed-tar" = app;
          "application/x-tar" = app;
          "application/x-xar" = app;
          "application/x-xz" = app;
          "application/x-xz-compressed-tar" = app;
          "application/zip" = app;
          "application/gzip" = app;
          "application/bzip2" = app;
          "application/vnd.rar" = app;
          "application/zstd" = app;
          "application/x-zstd-compressed-tar" = app;
        };
    };

    portal = {
      configPackages = [ pkgs.gnome-keyring ];
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    userDirs = {
      enable = true;
      setSessionVariables = true;
    };
  };

  home.pointerCursor = {
    enable = true;
    inherit (desktopConfig.pointerCursor) package name size;
    gtk = {
      enable = true;
      size = 32;
    };
    hyprcursor = {
      enable = true;
      size = 32;
    };
    sway.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      package = pkgs.inter;
      name = "Inter";
    };
    theme = {
      package = pkgs.colloid-gtk-theme;
      name = "Colloid-Dark";
    };
    gtk4.theme = config.gtk.theme;
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
}
