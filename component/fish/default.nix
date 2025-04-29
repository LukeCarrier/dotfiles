{ pkgs, ... }:
{
  # Fish isn't POSIX compliant, so making it the user shell is ill advised.
  # Has to tolerate stupid macOS ps.

  programs.zsh.initContent = ''
    parent_comm=$(ps -p $PPID -o comm=)
    if [[ $- == *i* ]] && [[ "$parent_comm" != "fish" ]] && [[ "$parent_comm" != *"OpenCode"* ]] && [[ -z ''${ZSH_EXECUTION_STRING} ]]; then
      [[ $- == *l* ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=
      exec fish $LOGIN_OPTION
    fi
  '';

  programs.bash.initExtra = ''
    parent_comm=$(ps -p $PPID -o comm=)
    if [[ $- == *i* ]] && [[ "$parent_comm" != "fish" ]] && [[ "$parent_comm" != *"OpenCode"* ]] && [[ -z ''${BASH_EXECUTION_STRING} ]]; then
      [[ $- == *l* ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=
      exec fish $LOGIN_OPTION
    fi
  '';

  programs.tmux.shell = "${pkgs.fish}/bin/fish";
}
