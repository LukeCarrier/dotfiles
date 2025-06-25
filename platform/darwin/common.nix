{ ... }:
{
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

    settings.experimental-features = [ "nix-command" "flakes" ];
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
