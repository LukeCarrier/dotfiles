{
  description = "Luke Carrier's dotfiles";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
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
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    darwin,
    flake-utils,
    home-manager,
    lanzaboote,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }:
  flake-utils.lib.eachDefaultSystem (system: {
    devShells.default =
      let
        pkgs = import nixpkgs { inherit system; };
      in
        pkgs.mkShell {
          packages = with pkgs; [ nil ];
        };
  }) // {
    darwinConfigurations = {
      fatman = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./platform/darwin/common.nix
          ./host/fatman/fatman.nix
        ];
      };
    };

    nixosConfigurations = {
      f1xable = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
          };
        };
        modules = [
          ./host/f1xable/hardware-configuration.nix
          ./hw/framework-13-amd.nix
          ./platform/nixos/enable-flakes.nix
          ./platform/nixos/region/en-gb.nix
          lanzaboote.nixosModules.lanzaboote
          ./platform/nixos/secure-boot.nix
          ./platform/nixos/graphical.nix
          ./platform/nixos/containers.nix
          ./host/f1xable/f1xable.nix
        ];
      };
    };

    homeConfigurations = {
      "lukecarrier@fatman" = home-manager.lib.homeManagerConfiguration {
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
