{ config, lib, ... }:
{
  services.hardware.bolt.enable = true;
  dotfiles.persistence.directories = lib.optional config.services.hardware.bolt.enable "/var/lib/boltd";
}
