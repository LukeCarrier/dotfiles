{ ... }:
{
  programs.ssh.matchBlocks.all = {
    match = "all";
    extraOptions = {
      IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
    };
  };

  programs.git.extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
}
