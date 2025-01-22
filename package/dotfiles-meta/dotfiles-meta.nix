{
  pkgs,
}:
let
  dfDevShell = pkgs.writeShellScriptBin "df-dev-shell" (builtins.readFile ./df-dev-shell);
in
pkgs.symlinkJoin {
  pname = "dotfiles-meta";
  version = "0.1.0";
  paths = [ dfDevShell ];
}
