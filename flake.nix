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
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/main";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      darwin,
      flake-utils,
      home-manager,
      lanzaboote,
      niri,
      nixos-hardware,
      nix-flatpak,
      nix-on-droid,
      nix-vscode-extensions,
      nixpkgs-unstable,
      sops-nix,
      waybar,
      wezterm,
      self,
      ...
    }:
    let
      pkgsForSystem = (
        { pkgs, system }:
        (import pkgs {
          inherit system;
          overlays = [
            niri.overlays.niri
            nix-vscode-extensions.overlays.default
            (final: prev: {
              waybar = waybar.packages.${system}.waybar.overrideAttrs {
                # "Did not find version * in the output of the command *"
                doInstallCheck = false;
              };
            })
            (final: prev: {
              aws-cli-tools = self.packages.${system}.aws-cli-tools;
              bw-cli-tools = self.packages.${system}.bw-cli-tools;
              docker-cli-tools = self.packages.${system}.docker-cli-tools;
              dotfiles-meta = self.packages.${system}.dotfiles-meta;
              kubernetes-client-tools = self.packages.${system}.kubernetes-client-tools;
              monaspace-fonts = self.packages.${system}.monaspace-fonts;
              stklos = self.packages.${system}.stklos;
              wezterm = wezterm.packages.${system}.default;
            })
            # NixOS/nixpkgs#380227
            (final: prev: {
              bitwarden-cli = prev.bitwarden-cli.overrideAttrs {
                dontCheckForBrokenSymlinks = true;
              };
            })
          ];
        })
      );
      desktopBackground = "~/Pictures/Wallpaper/Monochromatic mountains.jpg";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = pkgsForSystem ({
          pkgs = nixpkgs-unstable;
          system = system;
        });
      in
      {
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
              gnumake
              nil
              nix-index
              nixfmt-rfc-style
              sops
              treefmt
            ];
          };

          goDev = pkgs.mkShell {
            shellHook = ''
              echo -n "dlv "; dlv --version
              echo -n "go "; go --version
              echo -n "golangic-lint "; golangic-lint --version
              echo -n "golangci-lint-langserver "; golangci-lint-langserver --version
              echo -n "go "; go --version
              echo -n "make "; make --version
            '';
            packages = with pkgs; [
              delve
              gnumake
              go
              golangci-lint
              golangci-lint-langserver
              gopls
            ];
          };

          nodeDev = pkgs.mkShell {
            shellHook = ''
              echo -n "node "; node --version
              echo -n "pnpm "; pnpm --version
              echo -n "yarn "; yarn --version
            '';
            packages = with pkgs; [
              bun
              nodejs
              pnpm
              typescript-language-server
              yarn
            ];
          };

          kotlinDev = pkgs.mkShell {
            shellHook = ''
              kotlin -version
            '';
            packages = with pkgs; [
              kotlin
              kotlin-language-server
            ];
          };
        };

        packages = {
          aws-cli-tools = pkgs.callPackage ./package/aws-cli-tools/aws-cli-tools.nix { };

          bw-cli-tools = pkgs.callPackage ./package/bw-cli-tools/bw-cli-tools.nix { };

          docker-cli-tools = pkgs.callPackage ./package/docker-cli-tools/docker-cli-tools.nix { };

          dotfiles-meta = pkgs.callPackage ./package/dotfiles-meta/dotfiles-meta.nix { };

          kubernetes-client-tools =
            pkgs.callPackage ./package/kubernetes-client-tools/kubernetes-client-tools.nix
              { };

          monaspace-fonts = pkgs.callPackage ./package/monaspace-fonts/monaspace-fonts.nix {
            monaspace-fonts =
              let
                version = "1.101";
              in
              {
                inherit version;
                url = "https://github.com/githubnext/monaspace/releases/download/v${version}/monaspace-v${version}.zip";
                hash = "sha256-o5s4XBuwqA4sJ5KhEn5oYttBj4ojekr/LO6Ww9oQRGw=";
              };
          };

          stklos = pkgs.callPackage ./package/stklos/stklos.nix {
            stklos =
              let
                version = "2.10";
              in
              {
                inherit version;
                url = "https://stklos.net/download/stklos-${version}.tar.gz";
                hash = "sha256-bb8DRfkgSP7GEzrW5V1x0L47d21YF0sIftCPfEsuoEE=";
              };
          };
        };
      }
    )
    // {
      darwinConfigurations = {
        B-4653 = darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          pkgs = pkgsForSystem ({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./hw/macbook.nix
            ./platform/darwin/common.nix
            ./host/b-4653/b-4653.nix
            ./employer/emed/darwin.nix
            ./system/aerospace/aerospace.nix
            ./system/1password/1password.nix
            ./system/finicky/darwin.nix
            ./system/gauntlet/darwin.nix
            ./system/jetbrains-toolbox/darwin.nix
            ./system/logseq/darwin.nix
          ];
        };

        luke-fatman = darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          pkgs = pkgsForSystem ({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./hw/macbook.nix
            ./platform/darwin/common.nix
            ./host/fatman/fatman.nix
            ./system/aerospace/aerospace.nix
            ./system/gauntlet/darwin.nix
            ./system/jetbrains-toolbox/darwin.nix
            ./system/logseq/darwin.nix
          ];
        };
      };

      nixOnDroidConfigurations = {
        # Not sure we can provide different configurations to different devices?
        default = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsForSystem ({
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
          pkgs = pkgsForSystem ({
            inherit system;
            pkgs = nixpkgs-unstable;
          });
          modules = [
            ./host/f1xable/hardware-configuration.nix
            nixos-hardware.nixosModules.framework-13-7040-amd
            nix-flatpak.nixosModules.nix-flatpak
            ./hw/framework-13-amd.nix
            ./host/f1xable/f1xable.nix
            ./platform/nixos/enable-flakes.nix
            ./platform/nixos/region/en-gb.nix
            lanzaboote.nixosModules.lanzaboote
            ./platform/nixos/secure-boot.nix
            ./platform/nixos/graphical.nix
            ./platform/wireguard/wireguard.nix
            ./platform/nixos/containers.nix
          ];
          specialArgs = {
            desktopConfig.background = desktopBackground;
          };
        };
      };

      homeConfigurations = {
        "luke.carrier@B-4653.hq.babylonhealth.com" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsForSystem ({
            system = "aarch64-darwin";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
            jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
          };
          modules = [
            ./user/b-4653/luke.carrier.nix
            ./employer/emed/emed.nix
            sops-nix.homeManagerModules.sops
            ./home/homebrew/homebrew.nix
            ./home/fonts/fonts.nix
            ./home/readline/readline.nix
            ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/fish/default.nix
            ./home/zsh/zsh.nix
            ./home/direnv/direnv.nix
            ./system/aerospace/home.nix
            ./system/1password/home.nix
            ./home/openssh/openssh.nix
            ./home/atuin/atuin.nix
            ./home/starship/starship.nix
            ./home/tmux/tmux.nix
            ./home/helix/helix.nix
            ./home/vscode/vscode.nix
            ./home/vim/vim.nix
            ./home/gnupg/gnupg.nix
            ./home/git/git.nix
            ./home/jj/jj.nix
            ./home/zoxide/zoxide.nix
            # FIXME ./home/espanso/espanso.nix
            ./home/alacritty/alacritty.nix
            ./home/wezterm/wezterm.nix
            ./home/aws/aws.nix
            ./home/kubernetes-client/kubernetes-client.nix
            ./home/lima/lima.nix
            ./home/rust/cargo.nix
          ];
        };

        "nix-on-droid@" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsForSystem ({
            system = "aarch64-linux";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
            jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
          };
          modules = [
            ./user/android/nix-on-droid.nix
            # FIXME ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/fish/default.nix
            ./home/zsh/zsh.nix
            ./home/direnv/direnv.nix
            ./home/openssh/openssh.nix
            ./home/starship/starship.nix
            ./home/git/git.nix
            ./home/helix/helix.nix
          ];
        };

        "lukecarrier@luke-f1xable" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = pkgsForSystem ({
            system = "x86_64-linux";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            desktopConfig = {
              background = desktopBackground;
              pointerCursor = {
                package = pkgs.bibata-cursors;
                name = "Bibata-Modern-Classic";
                size = 32;
              };
            };
            gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
            jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
          };
          modules = [
            niri.homeModules.niri
            nix-flatpak.homeManagerModules.nix-flatpak
            sops-nix.homeManagerModules.sops
            ./user/f1xable/lukecarrier.nix
            ./home/privacy/privacy.nix
            ./home/fonts/fonts.nix
            ./home/readline/readline.nix
            ./home/kanshi/kanshi.nix
            ./home/gnome-headless/gnome-headless.nix
            ./home/wofi/wofi.nix
            ./home/waybar/waybar.nix
            ./home/hyprcursor/hyprcursor.nix
            ./home/swayidle/swayidle.nix
            ./home/swaylock/swaylock.nix
            ./home/wpaperd/wpaperd.nix
            ./home/mako/mako.nix
            ./home/niri/niri.nix
            ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/fish/default.nix
            ./home/zsh/zsh.nix
            ./home/direnv/direnv.nix
            ./home/bitwarden/bitwarden.nix
            ./home/openssh/openssh.nix
            ./home/atuin/atuin.nix
            ./home/starship/starship.nix
            ./home/tmux/tmux.nix
            ./home/coder/coder.nix
            ./home/helix/helix.nix
            ./home/vim/vim.nix
            ./home/vscode/vscode.nix
            ./home/gnupg/gnupg.nix
            ./home/git/git.nix
            ./home/jj/jj.nix
            ./home/zoxide/zoxide.nix
            ./home/espanso/espanso.nix
            ./home/alacritty/alacritty.nix
            ./home/wezterm/wezterm.nix
            ./home/rust/cargo.nix
            ./home/aws/aws.nix
            ./home/kubernetes-client/kubernetes-client.nix
          ];
        };

        "lukecarrier@luke-fatman.peacehaven.carrier.family" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsForSystem ({
            system = "aarch64-darwin";
            pkgs = nixpkgs-unstable;
          });
          extraSpecialArgs = {
            gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
            jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
          };
          modules = [
            ./user/fatman/lukecarrier.nix
            sops-nix.homeManagerModules.sops
            ./home/homebrew/homebrew.nix
            ./home/fonts/fonts.nix
            ./home/readline/readline.nix
            ./home/bash/bash.nix
            ./home/fish/fish.nix
            ./home/zsh/zsh.nix
            ./home/fish/default.nix
            ./home/direnv/direnv.nix
            ./system/aerospace/home.nix
            ./home/openssh/openssh.nix
            ./home/atuin/atuin.nix
            ./home/starship/starship.nix
            ./home/tmux/tmux.nix
            ./home/helix/helix.nix
            ./home/vim/vim.nix
            ./home/gnupg/gnupg.nix
            ./home/git/git.nix
            ./home/jj/jj.nix
            ./home/zoxide/zoxide.nix
            # FIXME ./home/espanso/espanso.nix
            ./home/alacritty/alacritty.nix
            ./home/wezterm/wezterm.nix
            ./home/aws/aws.nix
            ./home/kubernetes-client/kubernetes-client.nix
            ./home/lima/lima.nix
            ./home/rust/cargo.nix
          ];
        };
      };
    };
}
