{ config, lib, pkgs, ... }:
{
  # FIXME: implement nix-darwin/nix-darwin#1035
  # networking.extraHosts = ''
  #   # babylonhealth/monoweb
  #   127.0.0.1 localhost.docker.babylontech.co.uk
  #   127.0.0.1 localhost.dev.babylontech.co.uk
  #   127.0.0.1 localhost.staging.babylontech.co.uk
  #   127.0.0.1 localhost.preprod.babylontech.co.uk
  #   127.0.0.1 localhost.ca.preprod.babylontech.co.uk
  #   127.0.0.1 localhost.sg.preprod.babylontech.co.uk
  # '';
  
  sops.secrets.nix-github-private = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "nix/github-private";
    path = "/etc/nix/github-private.env";
  };

  nix = {
    enable = true;
    settings = {
      trusted-substituters = [
        "https://nixpkgs-python.cachix.org"
        "https://nixpkgs-terraform.cachix.org"
      ];
      trusted-public-keys = [
        "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
        "nixpkgs-terraform.cachix.org-1:8Sit092rIdAVENA3ZVeH9hzSiqI/jng6JiCrQ1Dmusw="
      ];
    };
  };

  launchd.daemons.nix-daemon.serviceConfig = {
    ProgramArguments =
      let
        timeout = "${pkgs.coreutils}/bin/timeout";
      in lib.mkForce [
        "/bin/sh"
        "-c"
        ''
          set -e
          /bin/wait4path /nix/store
          if ${timeout} 30s wait4path ${config.sops.secrets.nix-github-private.path}; then
            set +e
            source ${config.sops.secrets.nix-github-private.path}
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
    brews = [
      "gh"
      "mas"
    ];

    casks = [
      "aws-vpn-client"
      "keycastr"
      "meetingbar"
      "meld"
      "microsoft-teams"
      "postman"
      "vnc-viewer"

      # Installed via the MDM
      # "slack"
    ];

    masApps = {
      Xcode = 497799835;
    };
  };
}
