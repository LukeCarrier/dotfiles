{
  config,
  lib,
  pkgs,
  ...
}:
let
  configsPath = "$HOME/.kube/configs";
  selectCmds = {
    config = rec {
      env = "KUBECONFIG";
      optionCmd =
        ''fzf --walker file --walker-root "${configsPath}" --delimiter / --with-nth -1 --preview 'cat {}' --prompt "Kubernetes configuration (currently $''
        + env
        + '')"'';
      value = ''$(printf "%s/%s" "${configsPath}" "$1")'';
      valueFish = ''(printf "%s/%s" "${configsPath}" $argv[1])'';
    };
    context = rec {
      env = "KUBECTX";
      optionCmdFish =
        ''kubectl config get-contexts --output name | fzf --preview-window wrap --preview 'kubectl config view --output jsonpath=\'{.contexts[?(@.name == "{}")]}\''' --prompt "Kubernetes context (currently $''
        + env
        + '')"'';
      optionCmd =
        ''kubectl config get-contexts --output name | fzf --preview-window wrap --preview 'kubectl config view --output jsonpath='{.contexts[?(@.name == "{}")]}''' --prompt "Kubernetes context (currently $''
        + env
        + '')"'';
      setCmd = ''kubectl config use-context "$'' + env + ''"'';
      value = "$1";
      valueFish = ''$argv[1]'';
    };
  };
in
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-client-tools
    krew
    kyverno
  ];

  home.sessionPath = [
    "$HOME/.krew/bin"
  ];

  home.file = {
    ".kube/go-template/resources.gotmpl".source = ./go-template/resources.gotmpl;
  };

  programs.bash.initExtra = lib.strings.concatStringsSep "\n" (
    lib.attrsets.attrValues (
      lib.attrsets.mapAttrs (
        name: options:
        ''
          kube-${name}() {
            if [[ -n "$1" ]]; then
              export ${options.env}="${options.value}"
            else
              export ${options.env}="$(${options.optionCmd})"
            fi
            echo "Selected $''
        + options.env
        + ''"
          }
        ''
      ) selectCmds
    )
  );
  programs.fish.functions = lib.attrsets.mapAttrs' (
    name: options:
    lib.attrsets.nameValuePair "kube-${name}" {
      body =
        ''
          if test -n "$argv[1]"
            export ${options.env}=${options.valueFish}
          else
            export ${options.env}=(${options.optionCmdFish or options.optionCmd})
          end
          ${options.setCmd or ""}
          echo "Selected $''
        + options.env
        + ''"'';
    }
  ) selectCmds;
  programs.zsh.initContent = config.programs.bash.initExtra;
}
