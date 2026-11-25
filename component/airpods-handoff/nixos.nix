{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    settings.General.DeviceID = "bluetooth:004C:0000:0000";
  };

  systemd.user.services.airpods-handoff = {
    description = "AirPods Linux-Apple Handoff";
    after = [ "pipewire.service" ];
    wantedBy = [ "default.target" ];
    path = [ pkgs.pulseaudio ];

    serviceConfig = {
      ExecStart = "${pkgs.airpods-handoff}/bin/airpods-handoff 34:0E:22:85:EE:AF";
      Restart = "on-failure";
    };
  };
}
