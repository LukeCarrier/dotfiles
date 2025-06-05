{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwarden-desktop
    bitwarden-cli
    bw-cli-tools
  ];

  home.sessionVariables.BITWARDEN_SSH_AUTH_SOCK = "$HOME/.bitwarden/ssh-agent.sock";

  programs.ssh.matchBlocks.all = {
    match = "all";
    extraOptions = {
      IdentityAgent = ''"~/.bitwarden/ssh-agent.sock"'';
    };
  };
}
