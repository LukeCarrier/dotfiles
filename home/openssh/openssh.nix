{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ openssh ];

  programs.ssh.enable = true;
  # Use Gnome Keyring instead
  services.ssh-agent.enable = false;
}
