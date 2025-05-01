{ ... }:
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
