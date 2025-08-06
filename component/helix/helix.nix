{ config, pkgs, ... }:
let
  lldbDapRustcPrimer = "${config.xdg.configHome}/helix/debug/lldb_dap_rustc_primer.py";
in {
  home.file."${lldbDapRustcPrimer}".source =
    ./.config/helix/debug/lldb_dap_rustc_primer.py;
  home.file."${config.xdg.configHome}/helix/themes/local_tokyonight_storm.toml".source =
    ./.config/helix/themes/local_tokyonight_storm.toml;

  xdg.mimeApps.defaultApplications =
    let
      app = "Helix.desktop";
    in {
      "text/plain" = app;
    };

  programs.helix = {
    enable = true;
    defaultEditor = true;

    languages = {
      language-server = {
        regal = {
          command = "regal";
        };
      };
      language = [
        {
          name = "rego";
          language-servers = [ "regal" "regols" ];
        }
        {
          name = "rust";
          debugger = {
            name = "lldb-dap";
            transport = "stdio";
            command = "lldb-dap";
            templates = [
              {
                name = "binary";
                request = "launch";
                completion = [
                  {
                    name = "binary";
                    completion = "filename";
                  }
                ];
                args = {
                  program = "{0}";
                  initCommands = [
                    "command script import ${lldbDapRustcPrimer}"
                  ];
                };
              }
            ];
          };
        }
      ];
    };

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
