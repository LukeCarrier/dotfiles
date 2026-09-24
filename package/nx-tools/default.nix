{ pkgs }:
let
  nxPick = pkgs.writeShellApplication {
    name = "nx-pick";
    runtimeInputs = with pkgs; [
      fzf
      jq
    ];
    text = builtins.readFile ./nx-pick.sh;
  };
in
pkgs.symlinkJoin {
  pname = "nx-tools";
  version = "0.1.0";
  paths = [ nxPick ];
  meta.mainProgram = "nx-pick";
}
