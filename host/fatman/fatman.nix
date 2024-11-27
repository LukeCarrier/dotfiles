{ ... }:
{
  system.stateVersion = 5;

  networking.hostName = "luke-fatman";
  networking.domain = "peacehaven.carrier.family";

  users.users.lukecarrier = {
    description = "Luke Carrier";
  };
}
