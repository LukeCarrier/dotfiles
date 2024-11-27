{
  description = "Luke Carrier's dotfiles";

  inputs = {
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    wezterm.url = "github:wez/wezterm/main?dir=nix";
  };

  outputs = {
    darwin,
    flake-utils,
    home-manager,
    lanzaboote,
    nixos-hardware,
    nix-on-droid,
    nixpkgs-unstable,
    wezterm,
    self,
    ...
  }:
  let
    pkgsForSystem = ({ pkgs, system }: (
      import pkgs {
        inherit system;
        overlays = [
          (final: prev: {
            bw-cli-tools = self.packages.${system}.bw-cli-tools;
            monaspace-fonts = self.packages.${system}.monaspace-fonts;
            stklos = self.packages.${system}.stklos;
            wezterm = wezterm.packages.${system}.default;
          })
          (final: prev: {
            flatpak = (import (builtins.fetchTarball {
              url = "https://github.com/NixOS/nixpkgs/archive/ee20248665468359a46992b9f4b19007ce7fa586.tar.gz";
              sha256 = "0r1cxhr75aiaz0bs7xh8ikvl9r22an3grzp6v2171nhn8cmiq02n";
            }) {
              inherit system;
            }).flatpak;
          })
        ];
      }
    ));
  in flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = pkgsForSystem({
        pkgs = nixpkgs-unstable;
        system = system;
      });
    in {
      devShells.default =
        pkgs.mkShell {
          packages = with pkgs; [ gnumake nil nix-index ];
        };

      packages =
        {
          bw-cli-tools = pkgs.callPackage ./package/bw-cli-tools/bw-cli-tools.nix {};

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
    }) // {
      darwinConfigurations = {
        B-4653 = darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          pkgs = pkgsForSystem({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./platform/darwin/common.nix
            ./host/b-4653/b-4653.nix
            ./system/1password/1password.nix
          ];
        };

        B-5091 = darwin.lib.darwinSystem rec {
          system = "x86_64-darwin";
          pkgs = pkgsForSystem({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./platform/darwin/common.nix
            ./host/b-5091/b-5091.nix
          ];
        };

        luke-fatman = darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          pkgs = pkgsForSystem({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./platform/darwin/common.nix
            ./host/fatman/fatman.nix
          ];
        };
      };

      nixOnDroidConfigurations = {
        # Not sure we can provide different configurations to different devices?
        default = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsForSystem({
            system = "aarch64-darwin";
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./platform/android/common.nix
            ./host/w1deboi/w1deboi.nix
          ];
        };
      };

      nixosConfigurations = {
        luke-f1xable = nixpkgs-unstable.lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgsForSystem({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./host/f1xable/hardware-configuration.nix
            nixos-hardware.nixosModules.framework-13-7040-amd
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
        "luke.carrier@B-4653.hq.babylonhealth.com" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = pkgsForSystem({
            system = "aarch64-darwin";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "6E9AF94A377C55A36474CB0235975DF6B96AFDC1";
          };
          modules = [
            ./user/b-4653/luke.carrier.nix
            ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/zsh/zsh.nix
            ./system/1password/home.nix
            ./home/openssh/openssh.nix
            ./home/starship/starship.nix
            ./home/helix/helix.nix
            ./home/git/git.nix
            ./home/alacritty/alacritty.nix
            ./home/wezterm/wezterm.nix
          ];
        };

        "luke.carrier@B-5091.hq.babylonhealth.com" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = pkgsForSystem({
            system = "x86_64-darwin";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "6E9AF94A377C55A36474CB0235975DF6B96AFDC1";
          };
          modules = [
            ./user/b-5091/luke.carrier.nix
            ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/zsh/zsh.nix
            ./home/openssh/openssh.nix
            ./home/starship/starship.nix
            ./home/helix/helix.nix
            ./home/git/git.nix
            ./home/alacritty/alacritty.nix
            ./home/wezterm/wezterm.nix
          ];
        };

        "nix-on-droid@" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsForSystem({
            system = "aarch64-linux";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "1CBBEBFE0CDC1C06DB324A7CCE439AFEC33D9E7F";
          };
          modules = [
            ./user/android/nix-on-droid.nix
            # ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/zsh/zsh.nix
            ./home/openssh/openssh.nix
            ./home/starship/starship.nix
            ./home/git/git.nix
            ./home/helix/helix.nix
          ];
        };

        "lukecarrier@luke-f1xable" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = pkgsForSystem({
            system = "x86_64-linux";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "1CBBEBFE0CDC1C06DB324A7CCE439AFEC33D9E7F";
          };
          modules = [
            ./user/f1xable/lukecarrier.nix
            ./home/fonts/fonts.nix
            ./home/hyprland/hyprland.nix
            ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/zsh/zsh.nix
            ./home/openssh/openssh.nix
            ./home/starship/starship.nix
            # ./home/espanso/espanso.nix
            ./home/git/git.nix
            ./home/helix/helix.nix
            ./home/alacritty/alacritty.nix
            ./home/wezterm/wezterm.nix
          ];
        };

        "lukecarrier@luke-fatman" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsForSystem({
            system = "aarch64-darwin";
            pkgs = nixpkgs-unstable;
          });
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
