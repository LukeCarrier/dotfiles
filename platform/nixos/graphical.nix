{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    firefoxpwa
    flatpak
    gnome-keyring
    gnome-software
    home-manager
  ];

  boot.initrd.systemd.enable = true;
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet" "splash" "boot.shell_on_fail"
    "loglevel=3" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3"
  ];
  boot.loader.timeout = 0;

  services.upower.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  networking.networkmanager.enable = true;
  services.avahi.enable = true;

  security.polkit.enable = true;

  services.xserver.enable = true;
  services.greetd.enable = true;
  programs.regreet = {
    enable = true;
    cageArgs = [ "-m" "last" "-s" ];
    settings = {
      GTK.application_prefer_dark_theme = true;
    };
  };
  programs.hyprland.enable = true;
  security.pam.services.hyprlock = {};

  services.printing.enable = true;
  services.flatpak = {
    enable = true;
    package = pkgs.flatpak;
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = with pkgs; [ firefoxpwa ];
  };
}
