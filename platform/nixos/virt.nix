{ config, lib, options, pkgs, ... }:
let
  homedAccounts = options ? dotfiles.accounts.users;
in
{
  config = lib.mkMerge [
    {
      dotfiles.persistence.directories = lib.optional config.virtualisation.libvirtd.enable "/var/lib/libvirt";

      virtualisation.libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;
      };

      networking.firewall.trustedInterfaces = [
        "virbr0"
        "virbr1"
      ];

      environment.systemPackages = [ pkgs.swtpm ];

      users.users = lib.mkIf (!homedAccounts) {
        lukecarrier.extraGroups = [
          "kvm"
          "libvirtd"
          "qemu-libvirtd"
        ];
      };
    }
    (lib.optionalAttrs homedAccounts {
      dotfiles.accounts.users.lukecarrier.extraGroups = [
        "kvm"
        "libvirtd"
        "qemu-libvirtd"
      ];
    })
  ];
}
