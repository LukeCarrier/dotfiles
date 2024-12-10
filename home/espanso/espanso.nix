{ pkgs, ... }:
let
  os = pkgs.lib.lists.last (pkgs.lib.strings.splitString "-" pkgs.system);
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
  };
}
