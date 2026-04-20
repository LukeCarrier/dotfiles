{ pkgs }:
let
  githubCloneMany = pkgs.writeShellScriptBin "github-clone-many.sh" (
    builtins.readFile ./github-clone-many.sh
  );
  githubWorkflowsReferencing = pkgs.writeShellScriptBin "github-workflows-referencing.sh" (
    builtins.readFile ./github-workflows-referencing.sh
  );
in
pkgs.symlinkJoin {
  pname = "github-cli-tools";
  version = "0.1.0";
  paths = [
    githubCloneMany
    githubWorkflowsReferencing
  ]
  ++ (with pkgs; [
    findutils
    gh
    gh-dash
    jq
    yq-go
  ]);
}
