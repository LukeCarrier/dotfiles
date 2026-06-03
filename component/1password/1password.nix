{ lib, pkgs, ... }:
let
  inherit (lib) getExe' mkIf;
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = [ pkgs.onepassword-tools ];

  # OpenTofu/Terraform only discover credentials helpers in their plugin
  # directory, never on PATH, so link the helper into place explicitly.
  home.file.".terraform.d/plugins/terraform-credentials-op".source =
    getExe' pkgs.onepassword-tools "terraform-credentials-op";

  programs.ssh.settings."Match all" = {
    IdentityAgent =
      if isDarwin
      then ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
      else ''"~/.1password/agent.sock"'';
  };

  programs.git.settings.gpg.ssh.program =
    if isDarwin
    then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else (getExe' pkgs._1password-gui "op-ssh-sign");

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
