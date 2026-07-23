{ lib, pkgs, ... }:
let
  inherit (pkgs) libvirt;
in
{
  systemd.services.libvirtd-minikube-network = {
    description = "Ensure the default libvirt network exists for minikube KVM2";
    after = [ "libvirtd.service" ];
    wants = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if ! ${libvirt}/bin/virsh net-info default > /dev/null 2>&1; then
        ${libvirt}/bin/virsh net-define /var/lib/libvirt/qemu/networks/default.xml
        ${libvirt}/bin/virsh net-autostart default
        ${libvirt}/bin/virsh net-start default
      fi
    '';
  };
}
