{
  pkgs,
}:
let
  dfNixDevelop = pkgs.writeShellScriptBin "df-nix-develop" (builtins.readFile ./df-nix-develop);
in
pkgs.symlinkJoin {
  pname = "dotfiles-meta";
  version = "0.1.0";
  paths = [ dfNixDevelop ];
}
