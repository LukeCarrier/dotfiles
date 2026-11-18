{ pkgs, ... }:
{
  programs.hex = {
    enable = true;
    autostart = true;
    package = pkgs.hex;
  };
}
