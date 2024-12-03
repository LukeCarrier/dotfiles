{ ... }:
{
  system.stateVersion = 5;

  nix.settings = {
    trusted-substituters = [
      "https://nixpkgs-python.cachix.org"
      "https://nixpkgs-terraform.cachix.org"
    ];
    trusted-public-keys = [
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      "nixpkgs-terraform.cachix.org-1:8Sit092rIdAVENA3ZVeH9hzSiqI/jng6JiCrQ1Dmusw="
    ];
  };

  networking.computerName = "B-4653";
  networking.hostName = "B-4653.hq.babylonhealth.com";
  networking.localHostName = "B-4653";

  users.users."luke.carrier" = {
    description = "Luke Carrier";
  };

  homebrew.casks = [
    "qobuz"
    "vnc-viewer"
  ];
}
