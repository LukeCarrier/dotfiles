{ config, ... }:
{
  sops.secrets = {
    "cyberhaven/backend" = {};
    "cyberhaven/installToken" = {};
    "falcon-sensor/cid" = {};
  };

  services = {
    cyberhaven = {
      enable = true;
      backendFile = config.sops.secrets."cyberhaven/backend".path;
      installTokenFile = config.sops.secrets."cyberhaven/installToken".path;
    };
    falcon-sensor = {
      enable = true;
      cidFile = config.sops.secrets."falcon-sensor/cid".path;
      kernelPackages = null;
    };
  };
}
