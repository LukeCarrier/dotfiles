{
  darwin,
  home-manager,
  lanzaboote,
  niri,
  nix-flatpak,
  nix-on-droid,
  nixos-hardware,
  nixpkgs-unstable,
  sops-nix,
  pkgsForSystem,
  desktopBackground,
}:
{
  darwinConfigurations = {
    b-4653 = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs =
        (pkgsForSystem {
          system = "aarch64-darwin";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      modules = [ ./b-4653 ];
      specialArgs = {
        inputs = {
          inherit sops-nix;
        };
      };
    };

    luke-fatman = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs =
        (pkgsForSystem {
          system = "aarch64-darwin";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      modules = [ ./luke-fatman ];
      specialArgs = {
        inputs = {
          inherit sops-nix;
        };
      };
    };
  };

  nixOnDroidConfigurations = {
    default = nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "aarch64-linux";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      modules = [ ./nix-on-droid ];
      extraSpecialArgs = {
        inputs = { };
      };
    };
  };

  nixosConfigurations = {
    luke-f1xable = nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs =
        (pkgsForSystem {
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      modules = [ ./luke-f1xable ];
      specialArgs = {
        desktopConfig.background = desktopBackground;
        inputs = {
          inherit
            nixos-hardware
            nix-flatpak
            sops-nix
            lanzaboote
            ;
        };
      };
    };
  };

  homeConfigurations = {
    "luke.carrier@B-4653.hq.babylonhealth.com" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "aarch64-darwin";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
        inputs = {
          inherit sops-nix;
        };
      };
      modules = [ ./b-4653/user/luke.carrier ];
    };

    "nix-on-droid@" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "aarch64-linux";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        inputs = { };
      };
      modules = [ ./nix-on-droid/user/nix-on-droid ];
    };

    "lukecarrier@luke-f1xable" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        desktopConfig = {
          background = desktopBackground;
          pointerCursor =
            let
              pkgs =
                (pkgsForSystem {
                  system = "x86_64-linux";
                  pkgs = nixpkgs-unstable;
                }).pkgs;
            in
            {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 32;
            };
        };
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        inputs = {
          inherit niri nix-flatpak sops-nix;
        };
      };
      modules = [ ./luke-f1xable/user/lukecarrier ];
    };

    "lukecarrier@luke-fatman.peacehaven.carrier.family" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "aarch64-darwin";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        inputs = {
          inherit sops-nix;
        };
      };
      modules = [ ./luke-fatman/user/lukecarrier ];
    };
  };
}
