{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubectx
    krew
    kyverno
  ];

  home.sessionPath = [
    "$HOME/.krew/bin"
  ];

  home.file = {
    ".kube/go-template/resources.gotmpl".source = ./go-template/resources.gotmpl;
  };
}
