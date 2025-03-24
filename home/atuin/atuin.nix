{ ... }:
{
  programs.atuin = {
    enable = true;
    settings = {
      enter_accept = false;
      filter_mode = "host";
      filter_mode_shell_up_key_binding = "session";
      keymap_mode = "vim-insert";
    };
  };
}
