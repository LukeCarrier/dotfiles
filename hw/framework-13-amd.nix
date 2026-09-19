{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
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
  resetTouchpad = pkgs.writeShellScriptBin "fw13-reset-touchpad" ''
    modprobe -r i2c_hid_acpi
    modprobe i2c_hid_acpi
  '';
  resetWifi = pkgs.writeShellScriptBin "fw13-reset-wifi" ''
    modprobe -r mt7921e
    modprobe mt7921e
  '';
  postResume = pkgs.writeShellScriptBin "fw13-post-resume" ''
    ${getExe resetTouchpad}
    ${getExe resetWifi}
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
    lidEventCommands = ''${getExe lidFprint}'';
  };

  systemd.services.fw13-post-resume = {
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
      ExecStart = "${getExe postResume}";
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
