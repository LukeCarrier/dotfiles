{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  vicinae = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
  settingsFile = "${config.xdg.configHome}/vicinae/nix.json";
  settingsJSON = pkgs.writeText "vicinae-nix.json" (builtins.toJSON {
    close_on_focus_loss = true;
    pop_to_root_on_close = true;
    font."normal".family = builtins.elemAt config.fonts.fontconfig.defaultFonts.sansSerif 0;
    font."normal".size = 12;
    theme = {
      light.name = "vicinae-light";
      dark = {
        name = "tokyo-night";
        icon_theme = "default";
      };
    };
    launcher_window.opacity = 0.98;
  });
in
{
  programs.vicinae = {
    enable = true;

    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };

    settingOverrides = [ settingsFile ];

    themes."tokyo-night" = {
      meta = {
        version = 1;
        name = "Tokyo Night";
        description = "Tokyo Night, matching the rest of the desktop";
        variant = "dark";
        inherits = "vicinae-dark";
      };
      colors = {
        core = {
          background = "#1a1b26";
          foreground = "#a9b1d6";
          secondary_background = "#24273a";
          border = "#414868";
          accent = "#7aa2f7";
        };
        accents = {
          blue = "#7aa2f7";
          green = "#9ece6a";
          magenta = "#bb9af7";
          orange = "#ff9e64";
          purple = "#9d7cd8";
          red = "#f7768e";
          yellow = "#e0af68";
          cyan = "#7dcfff";
        };
      };
    };
  };

  # Vicinae watches VICINAE_OVERRIDES paths and reloads config on change, but
  # home-manager managed files are store symlinks. Write a real, editable copy
  # of the settings on activation so runtime edits stick until the next switch.
  home.activation.vicinaeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -Dm644 ${settingsJSON} "${settingsFile}"
  '';

  programs.niri.launcher = [
    (getExe vicinae)
    "toggle"
  ];
  programs.niri.workspacePicker = [
    (getExe vicinae)
    "dmenu"
  ];
}
