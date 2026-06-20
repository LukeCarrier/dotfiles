{
  config,
  lib,
  ...
}:
let
  lockCmd = config.services.swayidle.events.lock;
in
{
  services.swayidle = {
    enable = true;

    events = {
      before-sleep = lockCmd;
    };

    timeouts = [
      {
        timeout = 120;
        command = lockCmd;
      }
    ];
  };
}
