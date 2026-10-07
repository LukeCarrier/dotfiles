{ pkgs, ... }:
{
  home.packages = with pkgs; [
    github-cli-tools
  ];
}
