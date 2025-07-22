{
  description = "Luke Carrier's dotfiles";

  inputs = {
    code-insiders = {
      url = "github:iosmanthus/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      code-insiders,
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
      nur,
      rust-overlay,
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
            code-insiders.overlays.default
            niri.overlays.niri
            nix-vscode-extensions.overlays.default
            nur.overlays.default
            rust-overlay.overlays.default
            (final: prev: {
              niri = niri.packages.${system}.niri-unstable;
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
              eww-niri-workspaces = self.packages.${system}.eww-niri-workspaces;
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
            nativeBuildInputs = with pkgs; [
              age
              gnumake
              nil
              nix-index
              nixfmt-rfc-style
              ssh-to-age
              sops
              treefmt
            ];
          };

          goDev = pkgs.mkShell {
            shellHook = ''
              echo -n "dlv "; dlv version | awk '/Version/{print $2}'
              go version
              echo -n "golangci-lint "; golangci-lint --version
              make --version | head -n 1
            '';
            nativeBuildInputs = with pkgs; [
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
            nativeBuildInputs = with pkgs; [
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
            nativeBuildInputs = with pkgs; [
              kotlin
              kotlin-language-server
            ];
          };

          pythonDev = pkgs.mkShell {
            shellHook = ''
              python --version
            '';
            packages =
              (with pkgs; [
                python314
              ])
              ++ (with pkgs.python312Packages; [
                jedi-language-server
                python-lsp-server
                ruff
              ]);
          };

          rustDev = pkgs.mkShell {
            shellHook = ''
              cargo --version
              rustc --version
            '';
            nativeBuildInputs = with pkgs; [
              lldb_19
              pkg-config
              rust-analyzer
              rust-bin.stable.latest.default
            ];
          };
        };

        packages = {
          aws-cli-tools = pkgs.callPackage ./package/aws-cli-tools/aws-cli-tools.nix { };

          bw-cli-tools = pkgs.callPackage ./package/bw-cli-tools/bw-cli-tools.nix { };

          docker-cli-tools = pkgs.callPackage ./package/docker-cli-tools/docker-cli-tools.nix { };

          dotfiles-meta = pkgs.callPackage ./package/dotfiles-meta/dotfiles-meta.nix { };

          eww-niri-workspaces = pkgs.callPackage ./package/eww-niri-workspaces/eww-niri-workspaces.nix {
            ewwNiriWorkspaces = rec {
              owner = "LukeCarrier";
              # FIXME: there are currently no tags available :-(
              rev = "refs/heads/main";
              version = "0.0.0-${rev}";
              hash = "sha256-w/qGm7eOIhN+Uzj5pFRWk3jLcL8ABo3SPzksOBtYgwM=";
              cargoHash = "sha256-45X5XrDC74znu78cKpsJ32OBpGiRNRXJ597/+c/Hcpk=";
            };
          };

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
            sops-nix.darwinModules.sops
            ./host/b-4653/b-4653.nix
            ./employer/emed/darwin.nix
            ./component/hammerspoon/hammerspoon.nix
            ./component/1password/1password.nix
            ./component/finicky/darwin.nix
            ./component/jetbrains-toolbox/darwin.nix
            ./component/vscode/darwin.nix
            ./component/logseq/darwin.nix
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
            ./component/hammerspoon/hammerspoon.nix
            ./component/logseq/darwin.nix
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
            sops-nix.nixosModules.sops
            ./hw/framework-13-amd.nix
            ./host/f1xable/f1xable.nix
            ./platform/nixos/common.nix
            ./platform/nixos/region/en-gb.nix
            lanzaboote.nixosModules.lanzaboote
            ./platform/nixos/secure-boot.nix
            ./platform/nixos/graphical.nix
            ./platform/nixos/containers.nix
            ./component/gnome-network-displays/gnome-network-displays.nix
            ./component/valent/valent.nix
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
            ./component/shell-essential/shell-essential.nix
            ./component/homebrew/homebrew.nix
            ./component/fonts/fonts.nix
            ./component/readline/readline.nix
            ./component/bash/bash.nix
            ./component/fish/fish.nix
            ./component/fish/default.nix
            ./component/zsh/zsh.nix
            ./component/direnv/direnv.nix
            ./component/firefox/firefox.nix
            ./component/hammerspoon/home.nix
            ./component/1password/home.nix
            ./component/openssh/openssh.nix
            ./component/atuin/atuin.nix
            ./component/starship/starship.nix
            ./component/tmux/tmux.nix
            ./component/helix/helix.nix
            ./component/vscode/vscode.nix
            ./component/vim/vim.nix
            ./component/gnupg/gnupg.nix
            ./component/git/git.nix
            ./component/jj/jj.nix
            ./component/zoxide/zoxide.nix
            # ./component/espanso/espanso.nix
            ./component/alacritty/alacritty.nix
            ./component/wezterm/wezterm.nix
            ./component/aws/aws.nix
            ./component/kubernetes-client/kubernetes-client.nix
            ./component/lima/lima.nix
            ./component/rust/cargo.nix
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
            ./component/shell-essential/shell-essential.nix
            # ./component/bash/bash.nix
            ./component/fish/fish.nix
            ./component/fish/default.nix
            ./component/zsh/zsh.nix
            ./component/direnv/direnv.nix
            ./component/hammerspoon/home.nix
            ./component/openssh/openssh.nix
            ./component/starship/starship.nix
            ./component/git/git.nix
            ./component/helix/helix.nix
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
            ./component/shell-essential/shell-essential.nix
            ./component/fonts/fonts.nix
            ./component/readline/readline.nix
            ./component/kanshi/kanshi.nix
            ./component/gnome-headless/gnome-headless.nix
            ./component/wofi/wofi.nix
            ./component/waybar/waybar.nix
            ./component/hyprcursor/hyprcursor.nix
            ./component/swayidle/swayidle.nix
            ./component/swaylock/swaylock.nix
            ./component/wpaperd/wpaperd.nix
            ./component/mako/mako.nix
            ./component/niri/niri.nix
            ./component/bash/bash.nix
            ./component/fish/fish.nix
            ./component/fish/default.nix
            ./component/zsh/zsh.nix
            ./component/direnv/direnv.nix
            ./component/firefox/firefox.nix
            # ./component/gnome-network-displays/home.nix
            ./component/valent/home.nix
            ./component/bitwarden/bitwarden.nix
            ./component/openssh/openssh.nix
            ./component/atuin/atuin.nix
            ./component/starship/starship.nix
            ./component/tmux/tmux.nix
            ./component/coder/coder.nix
            ./component/helix/helix.nix
            ./component/vim/vim.nix
            ./component/vscode/vscode.nix
            ./component/gnupg/gnupg.nix
            ./component/git/git.nix
            ./component/jj/jj.nix
            ./component/zoxide/zoxide.nix
            ./component/espanso/espanso.nix
            ./component/alacritty/alacritty.nix
            ./component/wezterm/wezterm.nix
            ./component/rust/cargo.nix
            ./component/aws/aws.nix
            ./component/kubernetes-client/kubernetes-client.nix
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
            ./component/shell-essential/shell-essential.nix
            ./component/homebrew/homebrew.nix
            ./component/fonts/fonts.nix
            ./component/readline/readline.nix
            ./component/bash/bash.nix
            ./component/fish/fish.nix
            ./component/zsh/zsh.nix
            ./component/fish/default.nix
            ./component/direnv/direnv.nix
            ./component/firefox/firefox.nix
            ./component/hammerspoon/home.nix
            ./component/openssh/openssh.nix
            ./component/atuin/atuin.nix
            ./component/starship/starship.nix
            ./component/tmux/tmux.nix
            ./component/helix/helix.nix
            ./component/vscode/vscode.nix
            ./component/vim/vim.nix
            ./component/gnupg/gnupg.nix
            ./component/git/git.nix
            ./component/jj/jj.nix
            ./component/zoxide/zoxide.nix
            # ./component/espanso/espanso.nix
            ./component/alacritty/alacritty.nix
            ./component/wezterm/wezterm.nix
            ./component/aws/aws.nix
            ./component/kubernetes-client/kubernetes-client.nix
            ./component/lima/lima.nix
            ./component/rust/cargo.nix
          ];
        };
      };
    };
}
