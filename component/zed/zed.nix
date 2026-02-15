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
      # Keybindings
      vim_mode = true;
      helix_mode = true;

      # UI
      theme = {
        mode = "system";
        light = "Ayu Light";
        dark = "Tokyo Night";
      };
      icon_theme = "Material Icon Theme";

      # Fonts
      ui_font_size = 16;
      agent_ui_font_size = 14;
      buffer_font_size = 14;
      ui_font_family = "IBM Plex Sans";
      buffer_font_family = "MonaspiceKr Nerd Font";
      terminal = {
        font_size = 12;
        font_family = "MonaspiceKr Nerd Font";
      };

      # Edit predictions
      show_edit_predictions = true;
      edit_predictions = {
        mode = "subtle";
      };

      # Zed Agent
      agent = {
        enabled = true;
        use_modifier_to_send = true;
        enable_feedback = false;
        default_model = {
          provider = "zed.dev";
          model = "claude-sonnet-4-5";
        };
        default_profile = "write";
        profiles = {};
        always_allow_tool_actions = false;
      };

      # Other agents
      agent_servers = {
        OpenCode = {
          type = "custom";
          command = "opencode";
          args = [ "acp" ];
        };
      };

      # Collaboration
      audio = {
        "experimental.auto_microphone_volume" = true;
      };
      calls = {
        "mute_on_join" = true;
      };
    };
  };
}
