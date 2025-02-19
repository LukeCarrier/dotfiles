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
      "postman"
      "vnc-viewer"

      # Installed via the MDM
      # "slack"
    ];
  };
}
