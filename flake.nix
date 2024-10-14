{
  description = "Luke Carrier's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    darwin,
    home-manager,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }:
  {
    darwinConfigurations = {
      "fatman" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./platform/darwin/common.nix
          ./host/fatman.nix
        ];
      };
    };

    nixosConfigurations = {};

    homeConfigurations = {
      "lukecarrier@fatman" = home-manager.lib.homeManagerConfiguration rec {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
        };
        extraSpecialArgs = {
          gitConfig.user.signingKey = "1CBBEBFE0CDC1C06DB324A7CCE439AFEC33D9E7F";
        };
        modules = [
          ./user/fatman/lukecarrier.nix
          ./home/git/git.nix
          ./home/alacritty/alacritty.nix
          ./home/helix/helix.nix
        ];
      };
    };
  };
}
