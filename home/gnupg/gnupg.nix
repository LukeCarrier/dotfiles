{ pkgs, ... }:
{
  services.gpg-agent =
    let
      os = pkgs.lib.lists.last (pkgs.lib.strings.splitString "-" pkgs.system);
      pinentries = {
        darwin = pkgs.pinentry_mac;
        linux = pkgs.pinentry-rof2;
      };
    in {
      enable = true;
      pinentryPackage = pinentries.${os};
    };

  programs.gpg.enable = true;
}