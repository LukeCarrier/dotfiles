{ ... }:
{
  nix-rosetta-builder = {
    enable = true;
    onDemand = true;
    memory = "16GiB";
  };

  nix = {
    distributedBuilds = true;

    settings.trusted-users = [ "@admin" ];
  };
}
