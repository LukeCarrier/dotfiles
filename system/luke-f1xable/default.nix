{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ../../hw/framework-13-amd.nix
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../platform/nixos/containers.nix
    ../../component/gnome-network-displays/gnome-network-displays.nix
    ../../component/valent/valent.nix
  ];

  system.stateVersion = "24.05";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamescope.enable = true;

  networking.hostName = "luke-f1xable";
  networking.domain = "peacehaven.carrier.family";

  boot.initrd.luks.devices."luks-d0d2e346-4317-481e-98cc-3a1d879f3b2a".device =
    "/dev/disk/by-uuid/d0d2e346-4317-481e-98cc-3a1d879f3b2a";

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  nix.settings = {
    trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  programs.adb.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.bash}/bin/bash -c 'echo 80 >/sys/class/power_supply/BAT?/charge_control_end_threshold'"
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  environment.systemPackages = [ pkgs.swtpm ];

  users.users.lukecarrier = {
    isNormalUser = true;
    description = "Luke Carrier";
    extraGroups = [
      "adbusers"
      "input"
      "kvm"
      "libvirtd"
      "qemu-libvirtd"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family"
    ];
  };
}
