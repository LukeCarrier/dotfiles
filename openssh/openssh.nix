{ config, pkgs, ... }:
{
  # Use Gnome Keyring instead
  services.ssh-agent.enable = false;
}
