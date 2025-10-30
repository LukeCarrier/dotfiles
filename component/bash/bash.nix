{ ... }:
{
  programs.bash.enable = true;
  programs.bash.initExtra = ''
    if [[ $- == *i* ]]; then
      set -o vi
    fi
  '';
}
