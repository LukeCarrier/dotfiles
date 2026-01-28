{ pkgs, ... }:
let
  inherit (pkgs) stdenv;
  dummy = stdenv.mkDerivation {
    pname = "dummy";
    version = "0";

    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
    '';
  };
in
{
  programs.zed-editor = {
    enable = true;
    package = if stdenv.hostPlatform.isDarwin then dummy else pkgs.zed-editor;

    extensions = [
      "tokyo-night"
    ];

    userSettings = {
      theme = {
        mode = "system";
        light = "Ayu Light";
        dark = "Tokyo Night";
      };

      ui_font_size = 14;
      agent_font_size = 14;
      buffer_font_family = "MonaspiceKr NF";
      buffer_font_size = 12;
      terminal = {
        font_family = "MonaspiceKr NF";
        font_size = 12;
      };

      vim_mode = true;
      helix_mode = true;
    };
  };
}
