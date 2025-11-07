{ pkgs, ... }:
let
  inherit (pkgs) stdenv;
  os = pkgs.lib.lists.last (pkgs.lib.strings.splitString "-" stdenv.hostPlatform.system);
  package = {
    darwin = pkgs.espanso;
    linux = pkgs.espanso-wayland;
  };
  dependencies = {
    darwin = [ ];
    linux = [ pkgs.wl-clipboard ];
  };
in
{
  home.packages = dependencies.${os};

  services.espanso = {
    enable = true;
    package = package.${os};
    configs.default.search_shortcut = "CTRL+SPACE";
  };

  home.file = {
    ".config/espanso/match/base.yml".source = ./match/base.yml;
    ".config/espanso/match/packages/github-urls/package.yml".source =
      ./match/packages/github-urls/package.yml;
  };
}
