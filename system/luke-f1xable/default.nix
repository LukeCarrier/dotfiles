{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) getExe;
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    inputs.vicinae.nixosModules.default
    ../../hw/framework-13-amd.nix
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../component/gnome-headless/nixos.nix
    ../../component/niri/nixos.nix
    ../../component/librepods/nixos.nix
    ../../component/minikube/nixos.nix
    ../../platform/nixos/containers.nix
    ../../platform/nixos/virt.nix
  ];

  system.stateVersion = "24.05";

  sops.defaultSopsFile = ../../secrets/personal.yaml;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamescope.enable = true;

  networking = {
    hostName = "luke-f1xable";
    domain = "peacehaven.carrier.family";

    extraHosts = ''
      127.0.0.1 buzz.throw.party
    '';
  };

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

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${getExe pkgs.bash} -c 'echo 80 >/sys/class/power_supply/BAT?/charge_control_end_threshold'"
  '';

  environment.systemPackages = with pkgs; [
    android-tools
  ];

  users.users.lukecarrier = {
    isNormalUser = true;
    description = "Luke Carrier";
    extraGroups = [
      "adbusers"
      "input"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family"
    ];
  };
}
