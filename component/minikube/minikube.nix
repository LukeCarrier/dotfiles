{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs) stdenv;

  minikube' = pkgs.symlinkJoin {
    name = "minikube-${pkgs.minikube.version}";
    paths = [ pkgs.minikube ];
    postBuild = ''
      rm -f "$out/bin/kubectl"
    '';
  };
in
{
  home.packages = with pkgs; [
    minikube'
  ] ++ lib.optionals stdenv.isLinux [
    libvirt
  ];

  home.activation.minikubeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${lib.getExe minikube'} config set driver kvm2
  '';
}
