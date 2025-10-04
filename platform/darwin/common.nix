{
  config,
  lib,
  ...
}:
{
  sops = {
    secrets.nix-github = {
      sopsFile = lib.mkDefault ../../secrets/personal.yaml;
      format = lib.mkDefault "yaml";
      key = lib.mkDefault "nix/github";
      path = "/etc/nix/github.env";
    };

    templates."nix-access-tokens".content = ''
      access-tokens = "github.com=${config.sops.placeholder.nix-github}"
    '';
  };

  nix = {
    enable = true;

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    optimise = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      };
    };

    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    extraOptions = ''
      !include ${config.sops.templates.nix-access-tokens.path}
    '';
  };

  system.defaults = {
    CustomSystemPreferences = {
      "com.apple.AppleMultitouchTrackpad" = {
        DragLock = false;
        Dragging = false;
        TrackpadThreeFingerDrag = true;
      };
    };
  };

  homebrew = {
    enable = true;

    casks = [
      "bettertouchtool"
      "librewolf"
      "qobuz"
      "swiftdefaultappsprefpane"
      "thunderbird"
      "wezterm"
    ];
  };
}
