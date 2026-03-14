{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.librepods ];

  hardware.bluetooth.settings.General.DeviceID = "bluetooth:004C:0000:0000";
}
