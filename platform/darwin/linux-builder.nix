{ ... }:
{
  nix-rosetta-builder = {
    enable = true;
    onDemand = true;
    memory = "16GiB";
  };

  nix = {
    distributedBuilds = true;
    buildMachines =
      lib.mkAfter (map (machine:
        if machine.hostName == "rosetta-builder"
        then machine // { maxJobs = 1; }
        else machine
      ) config.nix.buildMachines);

    settings.trusted-users = [ "@admin" ];
  };
}
