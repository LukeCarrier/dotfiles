{ ... }:
{
  # Written for stupid macOS ps

  programs.bash.initExtra = ''
    if [[ $- == *i* ]] && [[ $(ps -p $PPID -o comm=) != "fish" ]] && [[ -z ''${BASH_EXECUTION_STRING} ]]; then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=\'\'
      exec fish $LOGIN_OPTION
    fi
  '';

  programs.zsh.initExtra = ''
    if [[ $- == *i* ]] && [[ $(ps -p $PPID -o comm=) != "fish" ]] && [[ -z ''${ZSH_EXECUTION_STRING} ]]; then
      [[ $- == *l* ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=\'\'
      exec fish $LOGIN_OPTION
    fi
  '';
}
