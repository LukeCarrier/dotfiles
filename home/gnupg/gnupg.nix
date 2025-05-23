{ pkgs, ... }:
{
  services.gpg-agent =
    let
      os = pkgs.lib.lists.last (pkgs.lib.strings.splitString "-" pkgs.system);
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
