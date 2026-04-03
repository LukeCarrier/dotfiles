{ lib, ... }:
{
  nix-rosetta-builder = {
    enable = true;
    onDemand = true;
    memory = "16GiB";
  };

  nix = {
    distributedBuilds = true;
    buildMachines = lib.mkForce [
      {
        hostName = "rosetta-builder";
        system = "aarch64-linux";
        maxJobs = 1;
        supportedFeatures = [
          "nix-command"
          "flakes"
        ];
      }
    ];
    settings.trusted-users = [ "@admin" ];
  };
}
