{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;

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
    };
  };
}
