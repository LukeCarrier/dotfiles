{ pkgs, stdenv, ... }:
{
  services.espanso =
    let
      os = pkgs.lib.lists.last (pkgs.lib.strings.splitString "-" pkgs.system);
      package = {
        darwin = pkgs.espanso;
        linux = pkgs.espanso-wayland;
      };
    in {
      enable = true;
      package = package.${os};
    };
}
