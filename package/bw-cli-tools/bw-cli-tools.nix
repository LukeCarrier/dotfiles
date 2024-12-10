{ pkgs }:
let
  bwSession = pkgs.writeShellScriptBin "bw-session" (builtins.readFile ./bw-session);
  bwSshAdd = pkgs.writeShellScriptBin "bw-ssh-add" ''
    entry="$1"
    file="$2"
    bw get attachment "$file" --itemid "$entry" --raw \
      | BW_PASSWORD="$entry" SSH_ASKPASS="${bwSshAddAskpass}/bin/bw-ssh-add-askpass" ssh-add -
  '';
  bwSshAddAskpass = pkgs.writeShellScriptBin "bw-ssh-add-askpass" ''
    bw get password "$BW_PASSWORD"
  '';
in
pkgs.symlinkJoin {
  pname = "bw-cli-tools";
  version = "0.1.0";
  paths = [
    bwSession
    bwSshAdd
    bwSshAddAskpass
  ];
}
