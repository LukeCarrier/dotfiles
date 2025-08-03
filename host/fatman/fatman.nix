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

  homebrew = {
    brews = [
      "mas"
    ];
    casks = [
      "messenger"
      "signal"
      "telegram"
      "whatsapp"
    ];
    masApps = {
      Xcode = 497799835;
    };
  };
}
