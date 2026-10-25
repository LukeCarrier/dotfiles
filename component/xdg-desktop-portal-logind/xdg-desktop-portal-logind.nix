{ pkgs, lib, ... }:
let
  portalLogind = pkgs.writeShellScriptBin "xdg-desktop-portal-logind" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.systemd
        pkgs.coreutils
      ]
    }:$PATH
    exec ${pkgs.python3.withPackages (ps: [ ps.dbus-next ])}/bin/python3 ${./portal-logind.py} "$@"
  '';

  portal = pkgs.runCommand "xdg-desktop-portal-logind" { } ''
    mkdir -p $out/share/xdg-desktop-portal/portals
    mkdir -p $out/share/dbus-1/services

    cat >$out/share/xdg-desktop-portal/portals/logind.portal <<EOF
    [portal]
    DBusName=org.freedesktop.impl.portal.desktop.logind
    Interfaces=org.freedesktop.impl.portal.Inhibit;
    UseIn=niri;
    EOF

    cat >$out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.logind.service <<EOF
    [D-BUS Service]
    Name=org.freedesktop.impl.portal.desktop.logind
    Exec=${portalLogind}/bin/xdg-desktop-portal-logind
    EOF
  '';
in
{
  xdg.portal.extraPortals = [ portal ];
  xdg.portal.config.niri."org.freedesktop.impl.portal.Inhibit" = "logind";
}
