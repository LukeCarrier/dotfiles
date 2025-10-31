{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      bitwarden-cli
      bw-cli-tools
    ]
    ++ (if pkgs.stdenv.isLinux then [ pkgs.bitwarden-desktop ] else [ ]);

  home.sessionVariables.BITWARDEN_SSH_AUTH_SOCK = "$HOME/.bitwarden/ssh-agent.sock";

  programs.ssh.matchBlocks.all = {
    match = "all";
    extraOptions = {
      IdentityAgent = ''"~/.bitwarden/ssh-agent.sock"'';
    };
  };
}
