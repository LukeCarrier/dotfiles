{ config, pkgs, ... }:
{
  home.file = {
    "~/.config/alacritty/themes/tokyo-night-storm.toml".source
      = ./.config/alacritty/themes/tokyo-night-storm.toml;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      import = [
        "~/.config/alacritty/themes/tokyo-night-storm.toml"
      ];

      colors.draw_bold_text_with_bright_colors = true;

      font = {
        size = 12;
        normal.family = "JetBrainsMono Nerd Font";
      };

      mouse.hide_when_typing = true;

      scrolling.history = 0;

      window = {
        dynamic_padding = true;
        dynamic_title = true;
        option_as_alt = "both";
      };
    };
  };
}
