{ pkgs, ... }:
let
  gnome-control-center-wrapped = pkgs.symlinkJoin {
    name = "${pkgs.gnome-control-center.pname}-wrapped-${pkgs.gnome-control-center.version}";
    paths = [ pkgs.gnome-control-center ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/gnome-control-center" \
        --set XDG_CURRENT_DESKTOP GNOME
    '';
  };
in
{
  services.gnome = {
    gnome-online-accounts.enable = true;
    evolution-data-server.enable = true;
  };

  environment.systemPackages =
    [ gnome-control-center-wrapped ]
    ++ (with pkgs; [ gnome-online-accounts-gtk ]);
}
