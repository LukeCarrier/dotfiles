{ pkgs, ... }:
{
  home.packages = [ pkgs.openssh ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      forwardAgent = "no";
      addKeysToAgent = "no";
      compression = "no";
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
      hashKnownHosts = "no";
      userKnownHostsFile = "~/.ssh/known_hosts";
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
    };
  };

  # Use Gnome Keyring (Linux) or a password manager (macOS) instead
  services.ssh-agent.enable = false;
}
