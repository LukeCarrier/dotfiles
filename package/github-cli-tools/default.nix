{ pkgs }:
let
  githubCloneMany = pkgs.writeShellScriptBin "github-clone-many" (
    builtins.readFile ./github-clone-many.sh
  );
  githubDependabotMerge = pkgs.writeShellScriptBin "github-dependabot-merge" (
    builtins.readFile ./github-dependabot-merge.sh
  );
  githubSyncStack = pkgs.writeShellScriptBin "github-sync-stack" (
    builtins.readFile ./github-sync-stack.sh
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
    githubSyncStack
    githubWorkflowsReferencing
  ]
  ++ (with pkgs; [
    coreutils
    findutils
    gh
    gh-dash
    jq
    yq-go
  ]);
}
