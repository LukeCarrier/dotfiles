{
  inputs,
  ...
}:
{
  imports = [
    ../../hw/macbook.nix
    ../../platform/darwin/common.nix
    inputs.sops-nix.darwinModules.sops
    ../../employer/emed/darwin.nix
    ../../component/1password/1password.nix
    ../../component/finicky/darwin.nix
    ../../component/jetbrains-toolbox/darwin.nix
    ../../component/vscode/darwin.nix
    ../../component/logseq/darwin.nix
  ];

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
