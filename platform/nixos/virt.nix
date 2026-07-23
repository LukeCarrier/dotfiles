{ pkgs, ... }: {
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };

  networking.firewall.trustedInterfaces = [
    "virbr0"
    "virbr1"
  ];

  environment.systemPackages = [ pkgs.swtpm ];

  users.users.lukecarrier.extraGroups = [
    "kvm"
    "libvirtd"
    "qemu-libvirtd"
  ];
}
