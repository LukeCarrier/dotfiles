{ pkgs }:
let
  bwSession = pkgs.writeShellScriptBin "bw-session" (builtins.readFile ./bw-session);
  bwSsh = pkgs.writeShellScriptBin "bw-ssh" ''
    entry="$1"
    file="$2"
    bw get attachment "$file" --itemid "$entry" --raw \
      | BW_PASSWORD="$entry" SSH_ASKPASS="${bwSshAskpass}/bin/bw-ssh-askpass" ssh-add -
  '';
  bwSshAskpass = pkgs.writeShellScriptBin "bw-ssh-askpass" ''
    bw get password "$BW_PASSWORD"
  '';
in pkgs.symlinkJoin {
  pname = "bw-cli-tools";
  version = "0.1.0";
  paths = [ bwSession bwSsh bwSshAskpass ];
}
