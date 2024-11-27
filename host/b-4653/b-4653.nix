{ ... }:
{
  system.stateVersion = 5;

  networking.computerName = "B-4653";
  networking.hostName = "B-4653.hq.babylonhealth.com";
  networking.localHostName = "B-4653";

  users.users."luke.carrier" = {
    description = "Luke Carrier";
  };
}
