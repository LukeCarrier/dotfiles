{ lib, pkgs, ... }:
let
  resetCharging = pkgs.writeShellScriptBin "thinkpad-l14-reset-charging" ''
    set -euo pipefail
    ${pkgs.kmod}/bin/modprobe -r ucsi_acpi
    ${pkgs.kmod}/bin/modprobe ucsi_acpi
  '';
in
{
  imports = [
    ../component/bolt/nixos.nix
    ../component/fwupd/nixos.nix
  ];

  environment.systemPackages = [ resetCharging ];

  boot = {
    # ZFS only supports up to 7.2, so stay one release behind latest (7.3).
    kernelPackages = pkgs.linuxPackages_7_2;
    kernelPatches = [
      {
        name = "ucsi-init-retry";
        patch = ../package/linux/ucsi-init-retry.patch;
      }
    ];
    # Wait for the GPU to read DPRX instead of tearing down the DP tunnel.
    kernelParams = [ "thunderbolt.dprx_timeout=-1" ];
  };

  services.acpid = {
    enable = true;
  };

  # Without a daemon owning the ACPI platform profile, DYTC leaves it at
  # low-power indefinitely, which clamps the package to a 10W PL1 via the MMIO
  # RAPL interface -- below this chip's 15W base TDP. Selecting balanced raises
  # it to 40W.
  services.power-profiles-daemon.enable = true;

  # intel_pstate runs in active mode here, which only offers powersave and
  # performance, so the shared ondemand setting cannot apply. Drop it rather
  # than have cpufreq.service fail and a cpufreq_ondemand modprobe miss on
  # every boot; HWP with energy_performance_preference=performance is what we
  # want on this CPU regardless.
  powerManagement.cpuFreqGovernor = lib.mkForce null;

  # Cap battery charge at 80% to reduce wear.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_start_threshold}="75"
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_end_threshold}="80"
  '';

}
