{
  config,
  lib,
  inputs,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./disk-config-test.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    inputs.vicinae.nixosModules.default
    ../../hw/thinkpad-t14s-gen6.nix
    ../../platform/nixos/common.nix
    ../../platform/nixos/accounts.nix
    ../../platform/nixos/home-manager-first-login.nix
    ../../platform/nixos/region/en-gb.nix
    ../../platform/nixos/secure-boot.nix
    ../../platform/nixos/graphical.nix
    ../../platform/nixos/containers.nix
    ../../platform/nixos/virt.nix
    ../../component/gnome-headless/nixos.nix
    ../../employer/throwparty/nixos.nix
    ../../component/niri/nixos.nix
    ../../component/librepods/nixos.nix
    ../../component/gnome-network-displays/gnome-network-displays.nix
  ];

  system.stateVersion = "26.05";

  hardware.facter.reportPath = ./facter.json;

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  sops.defaultSopsFile = ../../secrets/throwparty.yaml;

  boot.lanzaboote.pkiBundle = lib.mkForce "/var/lib/sbctl";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamescope.enable = true;

  networking = {
    hostName = "luke-c0nstruct";
    domain = "peacehaven.carrier.family";
    hostId = "a20aa3f1";
  };

  boot.zfs = {
    forceImportRoot = false;
    unsafeAllowHibernation = true;
  };

  # Resume must inspect the LUKS-backed swap LV before ZFS changes disk state.
  boot.initrd.systemd.services.zfs-import-c0nstruct = {
    after = [ "systemd-hibernate-resume.service" ];
    script = lib.mkAfter ''
      ${config.boot.zfs.package}/sbin/zfs rollback -r c0nstruct/root@blank
    '';
  };

  dotfiles.persistence = {
    enable = true;
    root = "/persist";
  };

  services = {
    upower = {
      criticalPowerAction = "PowerOff";
      percentageAction = 5;
    };
    zfs.autoScrub = {
      enable = true;
      pools = [ "c0nstruct" ];
    };
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
      "https://vicinae.cachix.org"
    ];
    trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://vicinae.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

  dotfiles.accounts.users.lukecarrier = {
    uid = 1000;
    initialPassword = "nixos";
    description = "Luke Carrier";
    extraGroups = [
      "input"
      "networkmanager"
      "wheel"
    ];
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family"
    ];
  };

  services.openssh.settings = {
    KbdInteractiveAuthentication = false;
    PasswordAuthentication = false;
  };

  programs._1password-gui.polkitPolicyOwners = [ "lukecarrier" ];
}
