{
  inputs,
  ...
}:
{
  imports = [
    ../../hw/macbook.nix
    ../../platform/darwin/common.nix
    #../../platform/darwin/linux-builder.nix
    inputs.sops-nix.darwinModules.sops
    ../../component/bitwarden/darwin.nix
    #../../component/wifiman/darwin.nix
    #../../component/logseq/darwin.nix
    #../../component/espanso/darwin.nix
    ../../component/opencode/darwin.nix
    ../../component/zed/darwin.nix
  ];

  system.stateVersion = 6;

  networking = {
    computerName = "luke-c0nstruct";
    hostName = "luke-c0nstruct.peacehaven.carrier.family";
    localHostName = "luke-c0nstruct";
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
    ];
    masApps = {
      #Xcode = 497799835;
    };
  };
}
