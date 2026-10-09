{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    github-cli-tools
  ];

  sops.secrets = {
    npmrc = {
      format = "yaml";
      key = "npm/rc";
      path = "${config.home.homeDirectory}/.npmrc";
    };
    yarnrc = {
      format = "yaml";
      key = "yarn/rc";
      path = "${config.home.homeDirectory}/.yarnrc.yml";
    };
  };
}
