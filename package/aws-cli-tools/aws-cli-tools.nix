{ pkgs }:
let
  awsEcrAuth = pkgs.writeShellScriptBin "aws-ecr-auth" (builtins.readFile ./aws-ecr-auth);
  awsEksUpdateKubeconfig = pkgs.writeShellScriptBin "aws-eks-update-kubeconfig" (
    builtins.readFile ./aws-eks-update-kubeconfig
  );
  awsSsoGenProfiles = pkgs.writeShellScriptBin "aws-sso-gen-profiles" (
    builtins.readFile ./aws-sso-gen-profiles
  );
in
pkgs.symlinkJoin {
  pname = "aws-cli-tools";
  version = "0.1.0";
  paths =
    [
      awsEcrAuth
      awsEksUpdateKubeconfig
      awsSsoGenProfiles
    ]
    ++ (with pkgs; [
      awscli2
      gnused
      jq
    ]);
}
