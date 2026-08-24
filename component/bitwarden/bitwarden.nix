{ pkgs, ... }:
let
  inherit (pkgs) stdenv;
  inherit (stdenv.hostPlatform) isDarwin isLinux;
  socketPath =
    if isDarwin then
      "Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
    else
      ".bitwarden/ssh-agent.sock";
in
{
  home.packages =
    with pkgs;
    [
      bitwarden-cli
      bw-cli-tools
    ]
    ++ (if isLinux then [ pkgs.bitwarden-desktop ] else [ ]);

  home.sessionVariables = {
    BITWARDEN_SSH_AUTH_SOCK = "$HOME/${socketPath}";
    SSH_AUTH_SOCK = "$HOME/${socketPath}";
  };

  launchd.agents."family.carrier.luke.bitwarden-env" =
    if isDarwin then
      {
        enable = true;
        config = {
          Label = "Prepare environment variables";
          ProgramArguments = [
            "/bin/sh"
            "-c"
            (builtins.concatStringsSep " " [
              "/bin/launchctl"
              "setenv"
              "BITWARDEN_SSH_AUTH_SOCK"
              "$HOME/${socketPath}"
              "SSH_AUTH_SOCK"
              "$HOME/${socketPath}"
            ])
          ];
          RunAtLoad = true;
        };
      }
    else
      { };

  programs.ssh.settings."Match all" = {
    IdentityAgent = ''"~/${socketPath}"'';
  };
}
