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
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ../../hw/dell-precision-5530.nix
    ../../platform/nixos/common.nix
    ../../platform/nixos/region/en-gb.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../platform/nixos/containers.nix
    ../../employer/emed/nixos.nix
    ../../component/niri/nixos.nix
    ../../component/librepods/nixos.nix
    ../../component/1password/nixos.nix
  ];

  system.stateVersion = "25.11";

  sops.defaultSopsFile = ../../secrets/employer-emed.yaml;

  boot.lanzaboote.pkiBundle = lib.mkForce "/var/lib/sbctl";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamescope.enable = true;

  networking = {
    hostName = "luke-dr0ne";
    domain = "peacehaven.carrier.family";
  };

  boot.initrd.luks.devices."luks-443748a8-2466-4c7f-be09-28933ecc10fb".device =
    "/dev/disk/by-uuid/443748a8-2466-4c7f-be09-28933ecc10fb";

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

  environment.systemPackages = [ pkgs.swtpm ];

  users.users.lukecarrier = {
    isNormalUser = true;
    description = "Luke Carrier";
    extraGroups = [
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

  programs._1password-gui.polkitPolicyOwners = [ "lukecarrier" ];
}
