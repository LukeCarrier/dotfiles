{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    aws-cli-tools
    fzf
  ];

  programs.bash.shellAliases = {
    aws-profile = ''export AWS_PROFILE="$(aws configure list-profiles | fzf)"'';
  };
  programs.fish.shellAliases = {
    aws-profile = "export AWS_PROFILE=(aws configure list-profiles | fzf)";
  };
  programs.zsh.shellAliases = {
    aws-profile = config.programs.bash.shellAliases.aws-profile;
  };
}
