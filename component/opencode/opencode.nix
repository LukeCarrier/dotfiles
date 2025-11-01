{ pkgs, ... }:
{
  home.packages = [ pkgs.opencode ];

  home.file.".config/opencode/opencode.json".source = ./opencode.json;
}
