{ ... }:
{
  home.sessionVariables = {
    HOMEBREW_DEVELOPER = 1;
    HOMEBREW_NO_INSTALL_FROM_API = 1;
  };

  programs.bash.profileExtra = ''
    if [[ "$(arch)" = "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  '';

  programs.fish.shellInit = ''
    set cpu_arch (arch)
    if [ $cpu_arch = "arm64" ];
      /opt/homebrew/bin/brew shellenv | source
    else
      /usr/local/bin/brew shellenv | source
    end
    set -e cpu_arch
  '';

  programs.zsh.profileExtra = ''
    if [[ "$(arch)" = "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  '';
}
