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

  programs.bash.initExtra = ''
    kube-config() {
      if [[ -n "$1" ]]; then
        export KUBECONFIG="$1"
      else
        export KUBECONFIG="$(${selectConfigCmd})"
      fi
      echo "Selected $KUBECONFIG"
    }
  '';
  programs.fish.functions.kube-config.body = ''
    if test -n "$argv[1]"
      export KUBECONFIG=$argv[1]
    else
      export KUBECONFIG=(${selectConfigCmd})
    end
    echo "Selected $KUBECONFIG"
  '';
  programs.zsh.initExtra = config.programs.bash.initExtra;
}
