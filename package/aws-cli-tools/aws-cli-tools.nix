{ pkgs }:
let
  awsSsoGenProfiles = pkgs.writeShellScriptBin "aws-sso-gen-profiles" (builtins.readFile ./aws-sso-gen-profiles);
in pkgs.symlinkJoin {
  pname = "aws-cli-tools";
  version = "0.1.0";
  paths = [ awsSsoGenProfiles pkgs.gnused ];
}
