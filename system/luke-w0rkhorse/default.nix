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
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../platform/nixos/containers.nix
    ../../platform/nixos/virt.nix
    ../../employer/emed/nixos.nix
    ../../component/niri/nixos.nix
    ../../component/librepods/nixos.nix
    ../../component/1password/nixos.nix
  ];

  system.stateVersion = "26.05";

  hardware.facter.reportPath = ./facter.json;

  sops.defaultSopsFile = ../../secrets/employer-emed.yaml;

  boot.lanzaboote.pkiBundle = lib.mkForce "/var/lib/sbctl";

  boot.kernelParams = [
    # Attempt to resolve issues with Thunderbolt docks after resuming from suspend
    # "usbcore.autosuspend=-1"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.hardware.bolt.enable = true;

  # Cap battery charge at 80% to reduce wear.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_end_threshold}="80"
  '';

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
      "https://cache.soopy.moe"
      "https://nix-community.cachix.org"
    ];
    trusted-substituters = [
      "https://cache.soopy.moe"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
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
