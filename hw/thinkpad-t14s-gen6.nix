{ lib, pkgs, ... }:
{
  imports = [
    ../component/bolt/nixos.nix
    ../component/fwupd/nixos.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
  };

  services.acpid = {
    enable = true;
  };

  # Without a daemon owning the ACPI platform profile, the firmware leaves it
  # at low-power and clamps the package indefinitely. Selecting balanced
  # restores the full power limit.
  services.power-profiles-daemon.enable = true;

  # graphical.nix pins ondemand globally, but the active pstate drivers
  # (intel_pstate/active, amd-pstate/active) don't expose it. Drop the governor
  # rather than have cpufreq.service fail with an ondemand modprobe miss on
  # every boot; energy_performance_preference is what we want anyway.
  powerManagement.cpuFreqGovernor = lib.mkForce null;

  # Cap battery charge at 80% to reduce wear.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_start_threshold}="75"
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_end_threshold}="80"
  '';

}
