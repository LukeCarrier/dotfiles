{ ... }:
{
  system.stateVersion = 5;

  networking = {
    computerName = "B-4653";
    hostName = "B-4653.hq.babylonhealth.com";
    localHostName = "B-4653";
  };

  users.users."luke.carrier" = {
    description = "Luke Carrier";
  };
  system.primaryUser = "luke.carrier";

  homebrew.casks = [
    "cursor"
    "visual-studio-code@insiders"
  ];
}
