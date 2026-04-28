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
      # Disable telemetry
      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      # Open projects in new windows
      cli_default_open_behavior = "new_window";

      # Window layout
      project_panel.dock = "left";
      outline_panel.dock = "left";
      collaboration_panel.dock = "left";
      git_panel."dock" = "left";
      agent = {
        dock = "right";
        enabled = true;
        use_modifier_to_send = true;
        enable_feedback = false;
      };
      agent_servers = {
        claude-acp.type = "registry";
        cline.type = "registry";
        codex-acp.type = "registry";
        crow-cli.type = "registry";
        cursor.type = "registry";
        deepagents.type = "registry";
        gemini.type = "registry";
        github-copilot-cli.type = "registry";
        goose.type = "registry";
        kilo.type = "registry";
        pi-acp.type = "registry";
        stakpak.type = "registry";
      };

      # Keybindings
      vim_mode = true;
      helix_mode = true;

      # UI
      theme = {
        mode = "system";
        light = "Ayu Light";
        dark = "Tokyo Night";
      };

      # Fonts
      ui_font_size = 16;
      ui_font_weight = 500;
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
