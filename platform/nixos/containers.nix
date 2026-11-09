{ lib, pkgs, ... }:
{
  virtualisation = {
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # virtualisation.docker.rootless installs docker.service as a global user
  # unit, so every user manager tries to start it. The greeter (uid 994) has no
  # subuid range, so rootlesskit fails three times and hits the start limit on
  # every boot. Only real login users need rootless docker.
  systemd.user.services.docker.unitConfig.ConditionUser = lib.mkForce "!@system";

  environment.systemPackages = with pkgs; [
    dive
    docker-client
    docker-compose
  ];
}
