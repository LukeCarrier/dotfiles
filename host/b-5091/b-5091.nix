{ ... }:
{
  system.stateVersion = 5;

  networking.computerName = "B-5091";
  networking.hostName = "B-5091.hq.babylonhealth.com";
  networking.localHostName = "B-5091";

  users.users."luke.carrier" = {
    description = "Luke Carrier";
  };
}
