{ pkgs }:
let
  githubCloneMany = pkgs.writeShellScriptBin "github-clone-many" (
    builtins.readFile ./github-clone-many.sh
  );
  githubDependabotMerge = pkgs.writeShellScriptBin "github-dependabot-merge" (
    builtins.readFile ./github-dependabot-merge.sh
  );
  githubWorkflowsReferencing = pkgs.writeShellScriptBin "github-workflows-referencing" (
    builtins.readFile ./github-workflows-referencing.sh
  );
in
pkgs.symlinkJoin {
  pname = "github-cli-tools";
  version = "0.1.0";
  paths = [
    githubCloneMany
    githubDependabotMerge
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
