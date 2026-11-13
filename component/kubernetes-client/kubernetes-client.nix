{
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
      optionCmd =
        ''kubectl config get-contexts --output name | fzf --preview-window wrap --preview 'kubectl config view --minify --context {}' --prompt "Kubernetes context (currently $''
        + env
        + '')"'';
      setCmd = ''kubectl config use-context "$selected"'';
      value = "$1";
      valueFish = ''$argv[1]'';
    };
  };

  kubeFunctions = lib.strings.concatStringsSep "\n" (
    lib.attrsets.attrValues (
      lib.attrsets.mapAttrs (
        name: options:
        ''
          kube-${name}() {
            local selected
            if [[ -n "$1" ]]; then
              selected="${options.value}" || return
            else
              selected="$(${options.optionCmd})" || return
            fi
            [[ -n "$selected" ]] || return 1
            ${lib.optionalString (options ? setCmd) "${options.setCmd} || return"}
            export ${options.env}="$selected"
            echo "Selected $''
        + options.env
        + ''
          "
                    }
        ''
      ) selectCmds
    )
  );
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

  programs.bash.initExtra = kubeFunctions;
  programs.fish.functions = lib.attrsets.mapAttrs' (
    name: options:
    lib.attrsets.nameValuePair "kube-${name}" {
      body = ''
        set -l selected
        if test -n "$argv[1]"
          set selected ${options.valueFish}
        else
          set selected (${options.optionCmd})
        end
        or return $status
        test -n "$selected"; or return 1
        ${lib.optionalString (options ? setCmd) "${options.setCmd}; or return $status"}
        export ${options.env}="$selected"
        echo "Selected $''
      + options.env
      + ''"'';
    }
  ) selectCmds;
  programs.zsh.initContent = kubeFunctions;
}
