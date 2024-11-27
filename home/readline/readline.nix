{ ... }:
{
  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      show-mode-in-prompt = "on";

      vi-cmd-mode-string = ''\1\e[1 q\2'';
      vi-ins-mode-string = ''\1\e[5 q\2'';

      keymap = "vi-insert";
    };
    bindings = {
      RETURN = ''\e\n'';
    };
  };
}
