{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
      configPackages = [ pkgs.gnome-keyring ];
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    userDirs.enable = true;
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 32;
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
}
