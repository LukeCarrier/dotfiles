{ pkgs, ... }:
{
  home.packages = [ pkgs.coder ];
  programs.ssh.includes = [
    "config_coder"
  ];
}
