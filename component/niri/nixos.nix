{ ... }:
{
  programs.niri.enable = true;

  services.nirinit = {
    enable = true;
    settings = {
      launch = {};
      skip.apps = [];
    };
  };
}
