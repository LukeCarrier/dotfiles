{ pkgs, ... }:
{
  # Fish isn't POSIX compliant, so making it the user shell is ill advised.
  # Has to tolerate stupid macOS ps.

  programs.bash.initExtra = ''
    if [[ $- == *i* ]] && [[ $(ps -p $PPID -o comm=) != "fish" ]] && [[ -z ''${BASH_EXECUTION_STRING} ]]; then
      [[ $- == *l* ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=
      exec fish $LOGIN_OPTION
    fi
  '';

  programs.zsh.initExtra = ''
    if [[ $- == *i* ]] && [[ $(ps -p $PPID -o comm=) != "fish" ]] && [[ -z ''${ZSH_EXECUTION_STRING} ]]; then
      [[ $- == *l* ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=
      exec fish $LOGIN_OPTION
    fi
  '';

  programs.tmux.shell = "${pkgs.fish}/bin/fish";
}
