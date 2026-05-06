{ ... }:
{
  programs.ashell = {
    enable = true;
    systemd.enable = true;
    settings = {
      appearance = {
        font_name = "Poppins";
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
            base = "#1a1b26";
            text = "#ffffff";
          }
        ];
      };
      modules = {
        left = [ "Workspaces" ];
        center = [ "Privacy" "SystemInfo" "MediaPlayer" ];
        right = [
          "Tempo"
          [ "Settings" "Tray" ]
        ];
      };
      workspaces.visibility_mode = "MonitorSpecific";
    };
  };
}
