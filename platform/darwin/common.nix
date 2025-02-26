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

    optimise.automatic = true;
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
      "qobuz"
      "wezterm"
    ];
  };
}
