{
  description = "Luke Carrier's dotfiles";

  inputs = {
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    darwin,
    flake-utils,
    home-manager,
    lanzaboote,
    nixpkgs,
    nixpkgs-unstable,
    self,
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

    packages =
      let
        pkgs = import nixpkgs { inherit system; };
        packages = {
          monaspace-fonts = pkgs.callPackage ./package/monaspace-fonts/monaspace-fonts.nix {
            monaspace-fonts = {
              url = "https://github.com/githubnext/monaspace/releases/download/v1.101/monaspace-v1.101.zip";
              sha256 = "0v2423dc75pf5kzllyi3ia7l3nv2d1z158cj4wn0xa5h3df3i6x3";
              version = "1.101";
            };
          };

          stklos = pkgs.callPackage ./package/stklos/stklos.nix {
            stklos = {
              url = "https://stklos.net/download/stklos-2.00.tar.gz";
              sha256 = "1jy7xvh8p4rcfcv4wqv43xxgi10wzw0ynyqm41wgpkhq596lb1gb";
              version = "2.00";
            };
          };
        };
      in
        packages;
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
          ./host/f1xable/f1xable.nix
          ./platform/nixos/enable-flakes.nix
          ./platform/nixos/region/en-gb.nix
          lanzaboote.nixosModules.lanzaboote
          ./platform/nixos/secure-boot.nix
          ./platform/nixos/graphical.nix
          ./platform/nixos/containers.nix
        ];
      };
    };

    homeConfigurations = {
      "lukecarrier@f1xable" = home-manager.lib.homeManagerConfiguration rec {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        extraSpecialArgs = {
          pkgs-unstable = import nixpkgs-unstable {
            system = pkgs.system;
          };
          gitConfig.user.signingKey = "1CBBEBFE0CDC1C06DB324A7CCE439AFEC33D9E7F";
        };
        modules = [
          ./user/f1xable/lukecarrier.nix
          ./home/hyprland/hyprland.nix
          ./home/bash/bash.nix
          ./home/fish/fish.nix
          ./home/zsh/zsh.nix
          ./home/openssh/openssh.nix
          ./home/starship/starship.nix
          ./home/espanso/espanso.nix
          ./home/git/git.nix
          ./home/helix/helix.nix
          ./home/alacritty/alacritty.nix
          ./home/wezterm/wezterm.nix
        ];
      };

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
