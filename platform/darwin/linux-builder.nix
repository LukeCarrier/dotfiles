{ ... }:
{
  nix-rosetta-builder = {
    enable = true;
    onDemand = true;
  };

  nix = {
    distributedBuilds = true;

    settings.trusted-users = [ "@admin" ];
  };
}
