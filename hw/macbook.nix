{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib) mkIf;
in
{
  security.pam.services.sudo_local.touchIdAuth = mkIf isDarwin true;
}
