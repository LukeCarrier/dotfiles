{ pkgs, ... }:
let
  inherit (pkgs) stdenv;
in
{
  programs.ghostty = {
    enable = true;

    package = if stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;

    settings = {
      background-blur = true;
      background-opacity = 0.85;
      window-padding-x = 8;
      window-padding-y = 8;

      font-family = "MonaspiceKr NF";
      font-family-bold = "MonaspiceKr NF Bold";
      font-family-italic = "MonaspiceKr NF Italic";
      font-family-bold-italic = "MonaspiceKr NF Bold Italic";
      font-size = 14;

      theme = "TokyoNight Storm";

      keybind = [
        "clear"
        "ctrl+shift+,=reload_config"
        "performable:copy=copy_to_clipboard:mixed"
        "paste=paste_from_clipboard"
        "performable:shift+insert=paste_from_selection"
        "ctrl+shift+c=copy_to_clipboard:mixed"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+==increase_font_size:1"
        "ctrl++=increase_font_size:1"
        "ctrl+-=decrease_font_size:1"
        "ctrl+0=reset_font_size"
        "super+ctrl+shift+j=write_screen_file:copy,plain"
        "ctrl+shift+j=write_screen_file:paste,plain"
        "ctrl+alt+shift+j=write_screen_file:open,plain"
        "shift+arrow_left=adjust_selection:left"
        "shift+arrow_right=adjust_selection:right"
        "shift+arrow_up=adjust_selection:up"
        "shift+arrow_down=adjust_selection:down"
        "shift+page_up=scroll_page_up"
        "shift+page_down=scroll_page_down"
        "shift+home=scroll_to_top"
        "shift+end=scroll_to_bottom"
        "ctrl+shift+tab=previous_tab"
        "ctrl+tab=next_tab"
        "ctrl+shift+n=new_window"
        "ctrl+shift+w=close_tab:this"
        "ctrl+shift+q=quit"
        "alt+f4=close_window"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+arrow_left=previous_tab"
        "ctrl+shift+arrow_right=next_tab"
        "ctrl+page_up=previous_tab"
        "ctrl+page_down=next_tab"
        "ctrl+shift+o=new_split:right"
        "ctrl+shift+e=new_split:down"
        "super+ctrl+[=goto_split:previous"
        "super+ctrl+]=goto_split:next"
        "ctrl+alt+arrow_up=goto_split:up"
        "ctrl+alt+arrow_down=goto_split:down"
        "ctrl+alt+arrow_left=goto_split:left"
        "ctrl+alt+arrow_right=goto_split:right"
        "super+ctrl+shift+arrow_up=resize_split:up,10"
        "super+ctrl+shift+arrow_down=resize_split:down,10"
        "super+ctrl+shift+arrow_left=resize_split:left,10"
        "super+ctrl+shift+arrow_right=resize_split:right,10"
        "ctrl+shift+page_up=jump_to_prompt:-1"
        "ctrl+shift+page_down=jump_to_prompt:1"
        "ctrl+shift+f=start_search"
        "performable:escape=end_search"
        "ctrl+shift+i=inspector:toggle"
        "ctrl+shift+a=select_all"
        "alt+digit_1=goto_tab:1"
        "alt+1=goto_tab:1"
        "alt+digit_2=goto_tab:2"
        "alt+2=goto_tab:2"
        "alt+digit_3=goto_tab:3"
        "alt+3=goto_tab:3"
        "alt+digit_4=goto_tab:4"
        "alt+4=goto_tab:4"
        "alt+digit_5=goto_tab:5"
        "alt+5=goto_tab:5"
        "alt+digit_6=goto_tab:6"
        "alt+6=goto_tab:6"
        "alt+digit_7=goto_tab:7"
        "alt+7=goto_tab:7"
        "alt+digit_8=goto_tab:8"
        "alt+8=goto_tab:8"
        "alt+9=last_tab"
        "ctrl+shift+enter=toggle_split_zoom"
        "ctrl+shift+p=toggle_command_palette"
      ];
    };
  };
}
