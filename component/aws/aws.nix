{ config, lib, pkgs, ... }:
let
  inherit (lib) getExe';
  awsConfigureViewProfile = getExe' pkgs.aws-cli-tools "aws-configure-view-profile";
  selectProfileCmd = ''
    aws configure list-profiles | fzf --preview '${awsConfigureViewProfile} {}' --prompt "AWS profile (currently $AWS_PROFILE)"
  '';
in
{
  home.packages = with pkgs; [
    awscli2
    aws-cli-tools
    fzf
  ];

  programs.bash.shellAliases.aws-profile = ''
    export AWS_PROFILE="$(${selectProfileCmd})"
    echo "Selected $AWS_PROFILE"
  '';
  programs.fish.functions.aws-profile.body = ''
    export AWS_PROFILE=(${selectProfileCmd})
    echo "Selected $AWS_PROFILE"
  '';
  programs.zsh.shellAliases.aws-profile = config.programs.bash.shellAliases.aws-profile;
}
