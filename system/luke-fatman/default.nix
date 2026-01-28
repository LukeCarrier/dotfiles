{
  inputs,
  ...
}:
{
  imports = [
    ../../hw/macbook.nix
    ../../platform/darwin/common.nix
    ../../platform/darwin/linux-builder.nix
    inputs.sops-nix.darwinModules.sops
    ../../component/wifiman/darwin.nix
    ../../component/logseq/darwin.nix
    ../../component/opencode/darwin.nix
    ../../component/zed/darwin.nix
  ];

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
      "handy"
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
