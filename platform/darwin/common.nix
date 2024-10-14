{ pkgs, ... }:
{
  services.nix-daemon.enable = true;

  nix = {
    configureBuildUsers = true;

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    optimise.automatic = true;
  };
}
