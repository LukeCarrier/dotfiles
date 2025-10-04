{ lib, ... }:
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

  sops.secrets.nix-github.sopsFile = lib.mkOverride 100 ../../secrets/employer-emed.yaml;

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
