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

    luke-c0nstruct = darwin.lib.darwinSystem rec {
      system = "x86_64-darwin";
      pkgs =
        (pkgsForSystem {
          inherit system;
          pkgs = nixpkgs-unstable;
        }).pkgs;
      modules = [ ./luke-c0nstruct ];
      specialArgs = {
        inputs = {
          inherit sops-nix;
        };
      };
    };

    luke-fatman = darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      pkgs =
        (pkgsForSystem {
          inherit system;
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
    luke-curs3d = nixpkgs-unstable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs =
        (pkgsForSystem {
          inherit system;
          pkgs = nixpkgs-unstable;
          config = {
            allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs-unstable.lib.getName pkg) [
                "cuda-merged"
                "nvidia-x11"
                "nvidia-settings"
                "nvidia-persistenced"
              ];
            cudaSupport = true;
          };
        }).pkgs;
      modules = [ ./luke-curs3d ];
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
    "luke.carrier@b-4653" = home-manager.lib.homeManagerConfiguration {
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

    "lukecarrier@luke-curs3d" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable;
          config.cudaSupport = true;
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
        kanshiConfig = [
          {
            output.criteria = "Samsung Electric Company U32J59x HTPK702789";
            output.mode = "3840x2160@60Hz";
            output.adaptiveSync = false;
            output.scale = 1.25;
            output.transform = null;
          }
          {
            profile.name = "peacehavenDockedClosed";
            profile.outputs = [
              {
                criteria = "Samsung Electric Company U32J59x HTPK702789";
                status = "enable";
                position = "0,0";
              }
            ];
          }
        ];
        inputs = {
          inherit niri nix-flatpak sops-nix;
        };
      };
      modules = [ ./luke-curs3d/user/lukecarrier ];
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
        kanshiConfig = [
          {
            output.criteria = "eDP-1";
            output.mode = "2880x1920@120Hz";
            output.adaptiveSync = true;
            output.scale = 1.25;
            output.transform = null;
          }
          {
            output.criteria = "Anker Innovations Limited CosmosLaser4k 0x00000001";
            output.mode = "3840x2160@60Hz";
            output.adaptiveSync = false;
            output.scale = 1.5;
            output.transform = null;
          }
          {
            output.criteria = "Samsung Electric Company U32J59x HTPK702789";
            output.mode = "3840x2160@60Hz";
            output.adaptiveSync = false;
            output.scale = 1.25;
            output.transform = null;
          }
          {
            output.criteria = "Samsung Electric Company U32J59x HTPK602008";
            output.mode = "3840x2160@30Hz";
            output.adaptiveSync = false;
            output.scale = 1.25;
            output.transform = null;
          }
          {
            output.criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
            output.mode = "1920x1080@60Hz";
            output.adaptiveSync = false;
            output.scale = 1.0;
            output.transform = null;
          }
          {
            profile.name = "mobile";
            profile.outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                position = "0,0";
              }
            ];
          }
          {
            profile.name = "peacehavenLounge";
            profile.outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                position = "0,0";
              }
              {
                criteria = "Anker Innovations Limited CosmosLaser4k 0x00000001";
                status = "enable";
                position = "0,3600";
              }
            ];
          }
          {
            profile.name = "peacehavenDockedClosed";
            profile.outputs = [
              {
                criteria = "eDP-1";
                status = "disable";
              }
              {
                criteria = "Samsung Electric Company U32J59x HTPK702789";
                status = "enable";
                position = "0,0";
              }
              {
                criteria = "Samsung Electric Company U32J59x HTPK602008";
                status = "enable";
                position = "3072,0";
              }
            ];
          }
          {
            profile.name = "peacehavenDockedOpen";
            profile.outputs = [
              {
                criteria = "Samsung Electric Company U32J59x HTPK702789";
                status = "enable";
                position = "0,0";
              }
              {
                criteria = "Samsung Electric Company U32J59x HTPK602008";
                status = "enable";
                position = "3072,0";
              }
              {
                criteria = "eDP-1";
                status = "enable";
                position = "4224,1728";
              }
            ];
          }
          {
            profile.name = "peacehavenSidecar";
            profile.outputs = [
              {
                criteria = "Samsung Electric Company U32J59x HTPK602008";
                status = "enable";
                position = "0,0";
              }
              {
                criteria = "eDP-1";
                status = "enable";
                position = "768,1728";
              }
            ];
          }
          {
            profile.name = "peacehavenMichaelDocked";
            profile.outputs = [
              {
                criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
                status = "enable";
                position = "0,0";
              }
              {
                criteria = "eDP-1";
                status = "enable";
                position = "1920,540";
              }
            ];
          }
        ];
        inputs = {
          inherit niri nix-flatpak sops-nix;
        };
      };
      modules = [ ./luke-f1xable/user/lukecarrier ];
    };

    "lukecarrier@luke-c0nstruct" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "x86_64-darwin";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        inputs = {
          inherit sops-nix;
        };
      };
      modules = [ ./luke-c0nstruct/user/lukecarrier ];
    };

    "lukecarrier@luke-fatman" = home-manager.lib.homeManagerConfiguration {
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
