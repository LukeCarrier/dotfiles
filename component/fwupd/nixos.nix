{ config, lib, ... }:
{
  services.fwupd.enable = true;
  dotfiles.persistence.directories = lib.optional config.services.fwupd.enable "/var/lib/fwupd";
}
