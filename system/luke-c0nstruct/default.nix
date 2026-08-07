{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.cyberhaven.nixosModules.cyberhaven
    inputs.falcon-sensor.nixosModules.default
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    inputs.nixos-hardware.nixosModules.apple-t2
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../platform/nixos/containers.nix
    ../../platform/nixos/virt.nix
    ../../employer/emed/nixos.nix
    ../../component/gnome-headless/nixos.nix
    ../../component/niri/nixos.nix
    ../../component/librepods/nixos.nix
    ../../component/1password/nixos.nix
  ];

  system.stateVersion = "26.05";

  sops.defaultSopsFile = ../../secrets/employer-emed.yaml;

  boot.lanzaboote.pkiBundle = lib.mkForce "/var/lib/sbctl";

  boot.kernelParams = [
    # Attempt to resolve issues with Thunderbolt docks after resuming from suspend
    "usbcore.autosuspend=-1"
    # The internal panel hangs off the AMD dGPU (the i915 eDP path is disabled),
    # so amdgpu failing to read the panel's DPCD/EDID on bring-up leaves us with a
    # blank or red screen. Disabling PSR works around the flaky eDP link training.
    "amdgpu.dcdebugmask=0x10"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.apple.touchBar = {
    enable = true;
    settings = {
      MediaLayerDefault = false;
      EnablePixelShift = true;
    };
  };

  services.hardware.bolt.enable = true;

  # Cap battery charge at 80% to reduce wear. On this T2 Mac the limit is an
  # SMC key (BCLM) exposed by the applesmc driver, not the standard
  # power_supply charge_control_end_threshold, so set it directly on the
  # acpi device whenever applesmc binds.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="acpi", DRIVER=="applesmc", ATTR{battery_charge_limit}="80"
  '';

  programs.gamescope.enable = true;

  networking = {
    hostName = "luke-c0nstruct";
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
