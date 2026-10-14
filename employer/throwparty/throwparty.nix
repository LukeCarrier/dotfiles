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

  programs.firefox.profiles.default.search.engines."throwparty/Go" = {
    definedAlias = [ "go" ];
    urls = [
      { template = "https://go.throw.party/{searchTerms}"; }
    ];
  };
}
