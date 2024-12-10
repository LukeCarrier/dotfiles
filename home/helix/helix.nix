{ config, pkgs, ... }:
{
  home.file."${config.xdg.configHome}/helix/themes/local_tokyonight_storm.toml".source =
    ./.config/helix/themes/local_tokyonight_storm.toml;

  programs.helix = {
    enable = true;
    settings = {
      theme = "local_tokyonight_storm";
      editor = {
        color-modes = true;
        cursorline = true;
        line-number = "relative";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker.hidden = false;
        indent-guides.render = true;
        soft-wrap.enable = true;
      };
    };
  };
}
