{
  darwin,
  home-manager,
  lanzaboote,
  niri,
  nix-flatpak,
  nix-on-droid,
  nix-rosetta-builder,
  nix-std,
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
      modules = [
        ./luke-fatman
      ];
      specialArgs = {
        inputs = {
          inherit nix-rosetta-builder sops-nix;
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
        inputs = {
          inherit
            nixos-hardware
            nix-flatpak
            sops-nix
            lanzaboote
            ;
        };
        desktopConfig.background = desktopBackground;
      };
    };

    luke-dr0ne = nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs =
        (pkgsForSystem {
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable;
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs-unstable.lib.getName pkg) [
              "1password"
              "1password-cli"
            ];
        }).pkgs;
      modules = [ ./luke-dr0ne ];
      specialArgs = {
        inputs = {
          inherit
            nixos-hardware
            nix-flatpak
            sops-nix
            lanzaboote
            ;
        };
        desktopConfig.background = desktopBackground;
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
        inputs = {
          inherit
            nixos-hardware
            nix-flatpak
            sops-nix
            lanzaboote
            ;
        };
        desktopConfig.background = desktopBackground;
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
        inputs = {
          inherit sops-nix;
        };
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
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
        inputs = { };
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
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
        inputs = {
          inherit niri nix-flatpak sops-nix;
        };
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
        kanshiConfig =
          let
            exec = "systemctl restart --user ashell.service wpaper.service";
          in
          [
            {
              output = {
                criteria = "Samsung Electric Company U32J59x HTPK702789";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.25;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Samsung Electric Company U32J59x HTPK602008";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.25;
                transform = null;
              };
            }
            {
              profile = {
                name = "peacehavenLeftOnly";
                outputs = [
                  {
                    criteria = "Samsung Electric Company U32J59x HTPK702789";
                    status = "enable";
                    position = "0,0";
                  }
                ];
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenRightOnly";
                profile.outputs = [
                  {
                    criteria = "Samsung Electric Company U32J59x HTPK602008";
                    status = "enable";
                    position = "0,0";
                  }
                ];
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenAll";
                outputs = [
                  {
                    criteria = "Samsung Electric Company U32J59x HTPK602008";
                    status = "enable";
                    position = "3072,0";
                  }
                  {
                    criteria = "Samsung Electric Company U32J59x HTPK702789";
                    status = "enable";
                    position = "0,0";
                  }
                ];
                inherit exec;
              };
            }
          ];
      };
      modules = [ ./luke-curs3d/user/lukecarrier ];
    };

    "lukecarrier@luke-dr0ne" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        inputs = {
          inherit niri nix-flatpak sops-nix;
        };
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
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 luke.carrier+id_ed25519_2025@emed.com";
        kanshiConfig =
          let
            exec = "systemctl restart --user ashell.service wpaper.service";
          in
          [
            {
              output = {
                criteria = "eDP-1";
                mode = "3840x2160@60Hz";
                adaptiveSync = true;
                scale = 1.75;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Anker Innovations Limited CosmosLaser4k 0x00000001";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.5;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Samsung Electric Company U32J59x HTPK702789";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.25;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Samsung Electric Company U32J59x HTPK602008";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.25;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
                mode = "1920x1080@60Hz";
                adaptiveSync = false;
                scale = 1.0;
                transform = null;
              };
            }
            {
              profile = {
                name = "mobile";
                outputs = [
                  {
                    criteria = "eDP-1";
                    status = "enable";
                    position = "0,0";
                  }
                ];
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenLounge";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenDockedClosed";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenDockedOpen";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenSidecar";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenMichaelDocked";
                  outputs = [
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
                inherit exec;
              };
            }
          ];
      };
      modules = [ ./luke-dr0ne/user/lukecarrier ];
    };

    "lukecarrier@luke-f1xable" = home-manager.lib.homeManagerConfiguration {
      pkgs =
        (pkgsForSystem {
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable;
        }).pkgs;
      extraSpecialArgs = {
        inputs = {
          inherit niri nix-flatpak sops-nix;
        };
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
        kanshiConfig =
          let
            exec = "systemctl restart --user ashell.service wpaper.service";
          in
          [
            {
              output = {
                criteria = "eDP-1";
                mode = "2880x1920@120Hz";
                adaptiveSync = true;
                scale = 1.5;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Anker Innovations Limited CosmosLaser4k 0x00000001";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.5;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Samsung Electric Company U32J59x HTPK702789";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.25;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Samsung Electric Company U32J59x HTPK602008";
                mode = "3840x2160@60Hz";
                adaptiveSync = false;
                scale = 1.25;
                transform = null;
              };
            }
            {
              output = {
                criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
                mode = "1920x1080@60Hz";
                adaptiveSync = false;
                scale = 1.0;
                transform = null;
              };
            }
            {
              profile = {
                name = "mobile";
                outputs = [
                  {
                    criteria = "eDP-1";
                    status = "enable";
                    position = "0,0";
                  }
                ];
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenLounge";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenDockedClosed";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenDockedOpen";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenSidecar";
                outputs = [
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
                inherit exec;
              };
            }
            {
              profile = {
                name = "peacehavenMichaelDocked";
                  outputs = [
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
                inherit exec;
              };
            }
          ];
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
        inputs = {
          inherit sops-nix;
        };
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
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
        inputs = {
          inherit sops-nix;
        };
        gitConfig.user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
        jjConfig.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW luke+id_ed25519_2025@carrier.family";
      };
      modules = [ ./luke-fatman/user/lukecarrier ];
    };
  };
}
