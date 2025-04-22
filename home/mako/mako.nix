{ pkgs, ... }:
{
  home.packages = [ pkgs.mako ];

  services.mako = {
    enable = true;
    borderColor = "#ffffff";
    borderRadius = 8;
    borderSize = 3;
    groupBy = "app-name";
    font = "Poppins 12";
    backgroundColor = "#000000bf";
    textColor = "#ffffff";
  };
}
