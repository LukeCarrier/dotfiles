{ pkgs, ... }:
{
  home.packages = [ pkgs.rift ];
  home.file.".config/rift/config.toml".source = ./config.toml;
}
