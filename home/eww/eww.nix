{ pkgs, ... }: {  
  home.packages = [ pkgs.eww-niri-workspaces ];
  programs.eww = {
    enable = true;
    configDir = ./config;
  };
}
