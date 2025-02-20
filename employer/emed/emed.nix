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
  '';
  programs.fish.functions.emed-mini-platform = ''
    ${selectMiniplatform}/bin/emed-mini-platform | source
  '';
  programs.zsh.initExtra = config.programs.bash.initExtra;
}
