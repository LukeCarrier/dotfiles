{ pkgs, ... }:
{
  home.packages = [ pkgs.mako ];

  services.mako = {
    enable = true;
    settings = {
      border-color = "#ffffff";
      border-radius = 8;
      border-size = 3;
      group-by = "app-name";
      font = "Poppins 12";
      background-color = "#000000bf";
      text-color = "#ffffff";
    };
  };
}
