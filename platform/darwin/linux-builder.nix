# This configuration really fucking sucks, but it's the best we can do.
#
# nix-rosetta-builder requires a Linux builder to exist to bootstrap its NixOS
# installation. nix.linux-builder doesn't provide a nice onDemand option, so
# once complete you'll want to disable it to save on resources.
{ lib, ... }:
{
  nix = {
    distributedBuilds = true;
    linux-builder = {
      enable = false;
      ephemeral = true;
    };
    settings.trusted-users = [ "@admin" ];
  };

  nix-rosetta-builder = {
    enable = true;
    onDemand = true;
    memory = "16GiB";
  };
}
