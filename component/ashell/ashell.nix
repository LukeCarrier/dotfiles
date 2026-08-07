{ config, lib, pkgs, ... }:
let
  inherit (lib) getExe;
in
{
  programs.ashell = {
    enable = true;
    systemd.enable = true;
    settings = {
      appearance = {
        font_name = builtins.elemAt config.fonts.fontconfig.defaultFonts.sansSerif 0;
        opacity = 0.8;
        menu.opacity = 0.8;
        primary_color = "#7aa2f7";
        success_color = "#9ece6a";
        text_color = "#a9b1d6";
        danger_color = {
          base = "#f7768e";
          weak = "#e0af68";
        };
        background_color = {
          base = "#1a1b26";
          weak = "#24273a";
          strong = "#414868";
        };
        secondary_color.base = "#0c0d14";
        workspace_colors = [
          {
            base = "#ffffff";
            strong = "#ffffff";
            weak = "#24273a";
            text = "#24273a";
          }
        ];
      };
      CustomModule = [
        (
          let
            inherit (pkgs) tardy;
            tardyBin = getExe tardy;
          in
          {
            name = "Tardy";
            type = "Button";
            listen_cmd = "${tardyBin} daemon --format=ashell";
            command = "${tardyBin} open";
          }
        )
      ];
      modules = {
        left = [ "Workspaces" ];
        center = [ "Privacy" "SystemInfo" "MediaPlayer" ];
        right = [
          "Tempo"
          "Tardy"
          [ "Settings" "Tray" ]
        ];
      };
      system_info.indicators = [ "Cpu" "Memory" "Temperature" "DownloadSpeed" "UploadSpeed" ];
      workspaces.visibility_mode = "MonitorSpecific";
    };
  };
}
