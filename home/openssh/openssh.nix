{ pkgs, ... }:
{
  home.packages = [ pkgs.openssh ];

  programs.ssh.enable = true;

  # Use Gnome Keyring (Linux) or a password manager (macOS) instead
  services.ssh-agent.enable = false;
}
