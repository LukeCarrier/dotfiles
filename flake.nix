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
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    wezterm.url = "github:wez/wezterm/main?dir=nix";
  };

  outputs = {
    darwin,
    flake-utils,
    home-manager,
    lanzaboote,
    nixpkgs-unstable,
    wezterm,
    self,
    ...
  }:
  flake-utils.lib.eachDefaultSystem (system: {
    devShells.default =
      let
        pkgs = import nixpkgs-unstable { inherit system; };
      in
        pkgs.mkShell {
          packages = with pkgs; [ gnumake nil ];
        };

    packages =
      let
        pkgs = import nixpkgs-unstable { inherit system; };
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
      luke-fatman = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./platform/darwin/common.nix
          ./host/fatman/fatman.nix
        ];
      };
    };

    nixosConfigurations = {
      luke-f1xable = nixpkgs-unstable.lib.nixosSystem rec {
        system = "x86_64-linux";
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
      "lukecarrier@luke-f1xable" = home-manager.lib.homeManagerConfiguration rec {
        pkgs = import nixpkgs-unstable {
          system = "x86_64-linux";
        };
        extraSpecialArgs = {
          pkgs-custom = self.packages.${pkgs.system};
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
           { programs.wezterm.package = wezterm.packages.${pkgs.system}.default; }
          ./home/wezterm/wezterm.nix
        ];
      };

      "lukecarrier@luke-fatman" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs-unstable {
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
