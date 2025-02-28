{ pkgs, ... }:
{
  home.packages = [ pkgs.bitwarden-desktop ];

  programs.ssh.matchBlocks.all = {
    match = "all";
    extraOptions = {
      IdentityAgent = ''"~/.bitwarden/ssh-agent.sock"'';
    };
  };
}
