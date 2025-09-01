{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # System management
    home-manager
    wirelesstools

    # Graphical sessions
    gnome-keyring
    gnome-software

    # Audio
    wiremix
  ];

  boot = {
    initrd = {
      systemd.enable = true;
      verbose = false;
    };

    plymouth = {
      enable = true;
      theme = "bgrt";
    };

    consoleLogLevel = 0;

    kernelModules = [
      # Dynamically loading this module means permissions don't get applied to
      # device nodes created when it's loaded, breaking some input methods.
      "uinput"
    ];

    kernelParams = [
      "quiet"
      "splash"
      "shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    loader.timeout = 3;
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  services.udisks2.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="input"
  '';

  services.upower.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    raopOpenFirewall = true;

    extraConfig.pipewire = {
      "10-airplay" = {
        "context.modules" = [
          {
            name = "libpipewire-module-raop-discover";
          }
        ];
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    input.General.UserspaceHID = true;
  };
  services.blueman.enable = true;

  networking.networkmanager.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  security.polkit.enable = true;

  services.xserver.enable = true;
  services.libinput.enable = true;
  services.greetd.enable = true;
  programs.regreet = {
    enable = true;
    cageArgs = [
      "-m"
      "last"
      "-s"
    ];
    settings = {
      GTK.application_prefer_dark_theme = true;
    };
  };

  # Won't have any effect on Niri, which we configure to use xwayland-satellite.
  programs.xwayland.enable = lib.mkForce true;
  programs.niri.enable = true;
  programs.hyprland.enable = true;
  security.pam.services.hyprlock = { };

  services.colord.enable = true;
  services.printing.enable = true;

  services.flatpak = {
    enable = true;
    package = pkgs.flatpak;
    overrides.global.Context.filesystems = [ "/nix/store:ro" ];
  };
}
