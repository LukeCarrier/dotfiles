{ pkgs }:
let
  terraformCredentialsOp = pkgs.writeShellScriptBin "terraform-credentials-op" (builtins.readFile ./terraform-credentials-op.sh);
in
pkgs.symlinkJoin {
  pname = "onepassword-tools";
  version = "0.1.0";
  paths = [ terraformCredentialsOp ];
}
