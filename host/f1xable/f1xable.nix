{ config, pkgs, ... }:
{
  system.stateVersion = "24.05";

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

  programs.adb.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.bash}/bin/bash -c 'echo 80 >/sys/class/power_supply/BAT?/charge_control_end_threshold'"
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      swtpm.enable = true;
    };
  };
  environment.systemPackages = [ pkgs.swtpm ];

  users.users.lukecarrier = {
    isNormalUser = true;
    description = "Luke Carrier";
    extraGroups = [
      "adbusers"
      "input"
      "kvm" "libvirtd" "qemu-libvirtd"
      "networkmanager"
      "wheel"
    ];
  };
}
