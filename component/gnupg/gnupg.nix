{ pkgs, ... }:
let
  inherit (pkgs) stdenv;
in
{
  services.gpg-agent =
    let
      os = pkgs.lib.lists.last (pkgs.lib.strings.splitString "-" stdenv.hostPlatform.system);
      pinentries = {
        darwin = pkgs.pinentry_mac;
        linux = pkgs.pinentry-tty;
      };
    in
    {
      enable = true;
      pinentry.package = pinentries.${os};
    };

  programs.gpg.enable = true;
}
