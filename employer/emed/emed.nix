{ config, pkgs, ... }:
let
  selectMiniplatform = pkgs.writeShellScriptBin "emed-mini-platform" ''
    fzf="${pkgs.fzf}/bin/fzf"
    yq="${pkgs.yq-go}/bin/yq"
    platforms="$HOME/.config/emed/miniplatforms.yaml"

    index="$("$yq" eval -r '. | keys[]' "$platforms" | \
      "$fzf" --preview "'$yq' eval '.[\"{}\"]' '$platforms'")"
    platform_integrations="$("$yq" eval -r ".$index.emed.platformIntegrations" "$platforms")"
    platform_services="$("$yq" eval -r ".$index.emed.platformServices" "$platforms")"
    aws_profile="$("$yq" eval -r ".$index.aws.profile" "$platforms")"
    aws_region="$("$yq" eval -r ".$index.aws.region" "$platforms")"
    env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws sts get-caller-identity >&2 || \
      env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws sso login >&2
    kubeconfig="$(printf %s/.kube/configs/%s "$HOME" "$("$yq" eval -r ".$index.kubeconfig" "$platforms")")"
    cluster="$(env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws ssm get-parameter \
        --name /eks/current_cluster --query Parameter.Value --output text)"

    printf 'export EMED_PLATFORM_INTEGRATIONS=%s\n' "$platform_integrations"
    printf 'export EMED_PLATFORM_SERVICES=%s\n' "$platform_services"
    printf 'export AWS_PROFILE=%s\n' "$aws_profile"
    printf 'export AWS_REGION=%s\n' "$aws_region"
    printf 'export KUBECONFIG=%s\n' "$kubeconfig"
    printf 'kubectl config use-context %s' "$aws_profile--$cluster"
  '';
in
{
  home.sessionPath = [
    "$HOME/Code/emed-labs/engineer-toolbox/bin"
    "$HOME/Code/emed-labs/nix/bin"
    # Jetbrains IDE wrappers
    "$HOME/.local/bin"
  ];
  
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

    SHIPCAT_MANIFEST_DIR = "$HOME/Code/babylonhealth/manifests";
  };

  # sops-nix is pretty weird, in that it won't resolve any of these values
  # during the Nix evaluation and will install a helper to do it when we switch
  # to the new generation. If secrets don't show up shortly after doing this,
  # check the logs for that helper tool, which can be found at:
  # ~/Libary/Logs/SopsNix/std{out,err}
  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  sops.secrets.finicky-config = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "finicky/config";
    path = "${config.home.homeDirectory}/.finicky.js";
  };

  sops.secrets.aws-config = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "aws/config";
    path = "${config.home.homeDirectory}/.aws/config";
  };
  sops.secrets.aws-saml2aws = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "aws/saml2aws/config";
    path = "${config.home.homeDirectory}/.saml2aws";
  };

  sops.secrets.npmrc = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "npm/rc";
    path = "${config.home.homeDirectory}/.npmrc";
  };
  sops.secrets.yarnrc = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "yarn/rc";
    path = "${config.home.homeDirectory}/.yarnrc.yml";
  };

  sops.secrets.pip-extra-index-urls-babylon = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "pip/extra_index_urls/babylon";
  };

  sops.secrets.emed-mini-platforms = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "miniplatforms/config";
    path = "${config.home.homeDirectory}/.config/emed/miniplatforms.yaml";
  };

  programs.bash.initExtra = ''
    emed-mini-platform() {
      eval "$(${selectMiniplatform}/bin/emed-mini-platform)"
    }

    export PIP_EXTRA_INDEX_URL_BABYLON="$(cat "${config.sops.secrets.pip-extra-index-urls-babylon.path}")"
  '';
  programs.fish.functions.emed-mini-platform = ''
    ${selectMiniplatform}/bin/emed-mini-platform | source
  '';
  programs.fish.shellInit = ''
    export PIP_EXTRA_INDEX_URL_BABYLON="$(cat "${config.sops.secrets.pip-extra-index-urls-babylon.path}")"
  '';
  programs.zsh.initContent = config.programs.bash.initExtra;
}
