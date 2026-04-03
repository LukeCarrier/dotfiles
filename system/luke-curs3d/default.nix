{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/cuda.nix
    ../../platform/nixos/graphical.nix
    ../../component/librepods/nixos.nix
    ../../component/niri/nvidia.nix
    ../../platform/nixos/containers.nix
    ../../component/gnome-network-displays/gnome-network-displays.nix
    ../../component/valent/valent.nix
  ];

  system.stateVersion = "25.11";

  boot.lanzaboote.pkiBundle = lib.mkForce "/var/lib/sbctl";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    open = true;
    nvidiaPersistenced = true;
    nvidiaSettings = true;
  };

  boot.kernelParams = [ "nvidia.NVreg_EnablePCIeGen3=1" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  programs.gamescope.enable = true;

  networking.hostName = "luke-curs3d";
  networking.domain = "peacehaven.carrier.family";

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

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };

  environment.systemPackages = with pkgs; [
    android-tools
    swtpm
  ];

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
