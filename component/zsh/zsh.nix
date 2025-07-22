{ config, pkgs, ... }:
{
  programs.zsh.enable = true;
  programs.zsh.initContent = ''
    if [[ -o interactive ]]; then
      bindkey -v

      function zle-keymap-select {
        if [[ ''${KEYMAP} == vicmd ]] ||
           [[ ''$1 = 'block' ]]; then
          echo -ne '\e[1 q'
        elif [[ ''${KEYMAP} == main ]] ||
             [[ ''${KEYMAP} == viins ]] ||
             [[ ''${KEYMAP} = '''''' ]] ||
             [[ $1 = 'beam' ]]; then
          echo -ne '\e[5 q'
        fi
      }

      zle -N zle-keymap-select
      echo -ne '\e[5 q'

      preexec() {
         echo -ne '\e[5 q'
      }
    fi
  '';
}
