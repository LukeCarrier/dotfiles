{ lib, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
                crypttabExtraOpts = [ "tpm2-device=auto" ];
              };
              content = {
                type = "lvm_pv";
                vg = "w0rkhorse";
              };
            };
          };
        };
      };
    };
    lvm_vg.w0rkhorse = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "64G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        zfs = {
          size = "100%FREE";
          content = {
            type = "zfs";
            pool = "w0rkhorse";
          };
        };
      };
    };
    zpool.w0rkhorse = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
        cachefile = "none";
      };
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        canmount = "off";
        compression = "zstd";
        dnodesize = "auto";
        mountpoint = "none";
        normalization = "formD";
        xattr = "sa";
      };
      postCreateHook = ''
        zfs list -t snapshot -H -o name | grep -Fxq 'w0rkhorse/root@blank' \
          || zfs snapshot w0rkhorse/root@blank
      '';
      datasets = {
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          options = {
            canmount = "noauto";
            mountpoint = "legacy";
          };
        };
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options = {
            canmount = "on";
            mountpoint = "legacy";
          };
        };
        home = {
          type = "zfs_fs";
          mountpoint = "/home";
          options = {
            canmount = "on";
            mountpoint = "legacy";
          };
        };
        persist = {
          type = "zfs_fs";
          mountpoint = "/persist";
          options = {
            canmount = "on";
            mountpoint = "legacy";
          };
        };
      };
    };
  };
}
