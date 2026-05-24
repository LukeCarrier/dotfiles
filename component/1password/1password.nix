{ lib, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin;
in
{
  programs.ssh.settings."Match all" = {
    IdentityAgent =
      if isDarwin
      then ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
      else ''"~/.1password/agent.sock"'';
  };

  programs.git.settings.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  launchd = mkIf isDarwin {
    enable = true;

    agents."family.carrier.1password.op-daemon" = {
      enable = true;
      config = {
        ProgramArguments = [
          "/opt/homebrew/bin/op"
          "daemon"
          "--timeout"
          "0"
          "--verbose"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
