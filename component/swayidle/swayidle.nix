{ config, lib, pkgs, ... }:
let
  inherit (lib) getExe getExe';
  systemctl = getExe' pkgs.systemd "systemctl";
  lockTimeoutSeconds = 120;
  lockCmd = config.services.swayidle.events.lock;
in
{
  services.swayidle = {
    enable = true;

    events = {
      before-sleep = lockCmd;
    };

    # swaywm/swayidle#198
    # swayidle is trying to observe logind idle inhibitors whenever it enables
    # timeouts, but as the change means that it will only connect to the bus if
    # after-sleep, before-resume or idlehint has been specified, it ends up
    # making all the sd_bus calls using a NULL bus pointer.
    extraArgs = [ "idlehint" (toString lockTimeoutSeconds) ];

    timeouts = [
      {
        timeout = 120;
        command = lockCmd;
      }
      {
        timeout = 300;
        command = "${systemctl} suspend-then-hibernate";
      }
    ];
  };
}
