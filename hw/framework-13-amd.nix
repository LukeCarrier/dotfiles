{ pkgs, ... }:
let
  lidFprint = pkgs.writeShellScriptBin "fw13-amd-lid-fprint" ''
    AUTH_PATH="/sys/bus/usb/devices/1-4:1.0/authorized"
    LID_PATH="/proc/acpi/button/lid/LID0/state"
    lid="$(cat "$LID_PATH")"
    lid="''${lid##* }"
    auth="0"
    if [[ "$lid" == "open" ]]; then
      auth="1"
    fi
    echo "$auth" >"$AUTH_PATH"
  '';
  resetWifi = pkgs.writeShellScriptBin "fw13-reset-wifi" ''
    modprobe -r mt7921e
    modprobe mt7921e
  '';
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Try to mitigate session-wide soft locks and artifacting in X11\
      # applications by disabling PSR and PR.
      "amdgpu.dcdebugmask=0x410"
    ];
  };

  services.acpid = {
    enable = true;
    lidEventCommands = ''${lidFprint}/bin/fw13-amd-lid-fprint'';
  };

  systemd.services.fw13-post-resume-reset-wifi = {
    description = "Local system resume actions";
    after = [
      "suspend.target"
      "hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${resetWifi}/bin/fw13-reset-wifi";
    };
  };

  services.fwupd = {
    enable = true;
    # FIXME: consider dropping this once Goodix fingerprint reader
    # firmware 01000334 lands in stable.
    extraRemotes = [ "lvfs-testing" ];
  };

  services.power-profiles-daemon.enable = true;

  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;

  services.hardware.bolt = {
    enable = true;
  };
}
