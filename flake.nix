{
  description = "Home Manager configuration of lukecarrier";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    home-manager,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."lukecarrier" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
          };
          gitConfig.user.signingKey = "1CBBEBFE0CDC1C06DB324A7CCE439AFEC33D9E7F";
          monaspace-fonts = {
            url = "https://github.com/githubnext/monaspace/releases/download/v1.101/monaspace-v1.101.zip";
            sha256 = "0v2423dc75pf5kzllyi3ia7l3nv2d1z158cj4wn0xa5h3df3i6x3";
            version = "1.101";
          };
        };

        modules = [
          ./home.nix
          ./hyprland/hyprland.nix
          ./bash/bash.nix
          ./fish/fish.nix
          ./zsh/zsh.nix
          ./openssh/openssh.nix
          ./starship/starship.nix
          ./git/git.nix
          ./helix/helix.nix
          ./alacritty/alacritty.nix
          ./wezterm/wezterm.nix
        ];
      };
    };
}
