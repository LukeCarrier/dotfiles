{ lib, pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
  };

  services.acpid = {
    enable = true;
  };

  services.fwupd.enable = true;

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

  swapDevices = [
    {
      device = "/swapfile";
      size = 64 * 1024;
    }
  ];

  services.upower = {
    criticalPowerAction = "Hibernate";
    percentageAction = 5;
  };

  services.hardware.bolt.enable = true;
}
