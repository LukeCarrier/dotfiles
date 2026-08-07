{
  lib,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    ./disk-config.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    inputs.cyberhaven.nixosModules.cyberhaven
    inputs.falcon-sensor.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ../../hw/thinkpad-l14.nix
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../platform/nixos/containers.nix
    ../../platform/nixos/virt.nix
    ../../component/gnome-headless/nixos.nix
    ../../employer/emed/nixos.nix
    ../../component/niri/nixos.nix
    ../../component/librepods/nixos.nix
    ../../component/1password/nixos.nix
    ../../component/gnome-network-displays/gnome-network-displays.nix
  ];

  system.stateVersion = "26.05";

  hardware.facter.reportPath = ./facter.json;

  sops.defaultSopsFile = ../../secrets/employer-emed.yaml;

  boot.lanzaboote.pkiBundle = lib.mkForce "/var/lib/sbctl";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamescope.enable = true;

  networking = {
    hostName = "luke-w0rkhorse";
    domain = "peacehaven.carrier.family";
  };

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
    efi.canTouchEfiVariables = true;
  };

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  users.users.lukecarrier = {
    isNormalUser = true;
    initialPassword = "nixos";
    description = "Luke Carrier";
    extraGroups = [
      "input"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family"
    ];
  };

  programs._1password-gui.polkitPolicyOwners = [ "lukecarrier" ];
}
