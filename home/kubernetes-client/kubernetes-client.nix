{ config, pkgs, ... }:
let
  selectConfigCmd = ''
    fzf --walker file --walker-root "$HOME/.kube/configs" --delimiter / --with-nth -1 --preview 'cat {}' --prompt "Kubernetes configuration (currently $KUBECONFIG)"
  '';
in
{
  home.packages = with pkgs; [
    kubectl
    krew
    kyverno
  ];

  home.sessionPath = [
    "$HOME/.krew/bin"
  ];

  home.file = {
    ".kube/go-template/resources.gotmpl".source = ./go-template/resources.gotmpl;
  };

  programs.bash.shellAliases.kube-config = ''
    export KUBECONFIG="$(${selectConfigCmd})"
    echo "Selected $KUBECONFIG"
  '';
  programs.fish.functions.kube-config.body = ''
    export KUBECONFIG=(${selectConfigCmd})
    echo "Selected $KUBECONFIG"
  '';
  programs.zsh.shellAliases.kube-config = config.programs.bash.shellAliases.kube-config;
}
