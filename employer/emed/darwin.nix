{ ... }:
{
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
