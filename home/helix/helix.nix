{ config, pkgs, ... }:
{
  home.file."${config.xdg.configHome}/helix/themes/local_tokyonight_storm.toml".source =
    ./.config/helix/themes/local_tokyonight_storm.toml;

  programs.helix = {
    enable = true;
    defaultEditor = true;

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
      keys.normal = {
        # Remap "goto x" commands to open in splits
        g =
          let
            gotoDefinitionKeys = {
              d = "goto_definition";
              D = "goto_declaration";
              f = "goto_file";
              i = "goto_implementation";
              y = "goto_type_definition";
            };
            gotoDefinitionSplitCmds = builtins.mapAttrs (key: value:
              [ "hsplit" "jump_view_up" value]);
          in gotoDefinitionSplitCmds gotoDefinitionKeys;
      };
    };
  };
}
