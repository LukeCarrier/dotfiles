{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
  };

  services.acpid = {
    enable = true;
  };

  services.fwupd.enable = true;

  # Cap battery charge at 80% to reduce wear.
  services.udev.extraRules = ''
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
