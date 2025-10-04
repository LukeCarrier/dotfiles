{
  config,
  lib,
  pkgs,
  ...
}:
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

    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
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

  sops.secrets.nix-github = {
    sopsFile = lib.mkDefault ../../secrets/personal.yaml;
    format = lib.mkDefault "yaml";
    key = lib.mkDefault "nix/github";
    path = "/etc/nix/github.env";
  };

  # Changes require restarting nix-daemon manually
  # sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
  # sudo launchctl load -w /Library/LaunchDaemons/org.nixos.nix-daemon.plist
  launchd.daemons.nix-daemon.serviceConfig = {
    ProgramArguments =
      let
        timeout = "${pkgs.coreutils}/bin/timeout";
      in
      lib.mkForce [
        "/bin/sh"
        "-c"
        ''
          set -e
          /bin/wait4path /nix/store
          if ${timeout} 30s wait4path ${config.sops.secrets.nix-github.path}; then
            set +e
            source ${config.sops.secrets.nix-github.path}
            set -e
          fi
          exec ${lib.getExe' config.nix.package "nix-daemon"}
        ''
      ];

    # If something seems wonky, troubleshoot with:
    #StandardOutPath = lib.mkForce "/tmp/nix-daemon-wrapper-stdout.log";
    #StandardErrorPath = lib.mkForce "/tmp/nix-daemon-wrapper-stderr.log";
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
