{ ... }:
{
  system.stateVersion = 5;

  networking = {
    computerName = "luke-fatman";
    hostName = "luke-fatman.peacehaven.carrier.family";
    localHostName = "luke-fatman";
  };

  users.users.lukecarrier = {
    description = "Luke Carrier";
  };
  system.primaryUser = "lukecarrier";
}
