{ config, pkgs, ... }:
{
  home.packages = [ pkgs.wofi ];

  home.file."${config.xdg.configHome}/wofi/style.css".text = ''
    @define-color default-fg #2d3e4e;
    @define-color invert-fg #ffffff;
    @define-color alert #eb4d4b;

    * {
      font-family: "${builtins.elemAt config.fonts.fontconfig.defaultFonts.sansSerif 0}", "Font Awesome 6 Free";
    }

    window, #outer-box {
      background-color: transparent;
      margin: 5px;
    }

    #input, #inner-box {
      margin: 0 5px;
      background-color: @default-fg;
    }

    #input {
      font-size: 3em;
    }

    .entry, .entry#selected, .entry#unselected {
      border-radius: 0;
    }
  '';
}
