{
  description = "Luke Carrier's dotfiles";

  inputs = {
    agentkit = {
      url = "github:throwparty/agentkit/nix-packages-overlay?dir=nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    ashell = {
      url = "github:MalpenZibo/ashell/0.8.0";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    code-insiders = {
      url = "github:iosmanthus/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    dagger = {
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-utils.url = "github:numtide/flake-utils";
    handy = {
      url = "github:cjpais/handy";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    niri-float-sticky = {
      url = "github:probeldev/niri-float-sticky";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/main";
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-std.url = "github:chessai/nix-std";
    nix-vscode-extensions = {
      url = "github:LukeCarrier/nix-vscode-extensions/unpack-phase";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    wpaperd = {
      url = "github:danyspin97/wpaperd";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-overlay.follows = "rust-overlay";
    };
  };

  outputs =
    {
      agentkit,
      ashell,
      claude-code,
      code-insiders,
      dagger,
      darwin,
      flake-utils,
      handy,
      home-manager,
      lanzaboote,
      niri,
      niri-float-sticky,
      nixos-hardware,
      nix-flatpak,
      nix-on-droid,
      nix-rosetta-builder,
      nix-std,
      nix-vscode-extensions,
      nixpkgs-unstable,
      nur,
      rust-overlay,
      sops-nix,
      wezterm,
      wpaperd,
      self,
      ...
    }:
    let
      desktopBackground = "~/Pictures/Wallpaper";
      pkgsForSystem =
        {
          pkgs,
          system,
          config ? { },
        }:
        let
          flakeUnfree = [
            # Add only unfree packages provided by this flake here. All others
            # belong in individual system and home manager configurations.
            "obsbot-sdk"
          ];
          mergedConfig = config // {
            allowUnfreePredicate =
              pkg:
              builtins.elem (basePkgs.lib.getName pkg) flakeUnfree
              || (config.allowUnfreePredicate or (_: false)) pkg;
          };
          basePkgs = import pkgs {
            inherit system;
            config = mergedConfig;
          };
          legacyPackages = import ./package/legacy-packages.nix { pkgs = basePkgs; };
        in
        {
          inherit legacyPackages;
          pkgs = basePkgs.appendOverlays [
            agentkit.overlays.default
            claude-code.overlays.default
            code-insiders.overlays.default
            dagger.overlays.default
            niri.overlays.niri
            nix-vscode-extensions.overlays.default
            nur.overlays.default
            rust-overlay.overlays.default
            wpaperd.overlays.default
            (final: prev: {
              ashell = ashell.packages.${system}.default.overrideAttrs (old: {
                patches = (old.patches or []) ++ [ ./package/ashell/pr-740.patch ];
              });
              direnv = prev.direnv.overrideAttrs (_old: {
                doCheck = false;
              });
              handy = handy.packages.${system}.handy.overrideAttrs (old: {
                buildInputs = (old.buildInputs or []) ++ [ basePkgs.wtype ];
                patches = (old.patches or []) ++ [ ./package/handy/pr-1337.patch ];
              });
              librewolf = prev.librewolf.overrideAttrs (old: {
                patches = (old.patches or []) ++ [ ./package/firefox/fractional-scale.patch ];
              });
              niri = niri.packages.${system}.niri-unstable;
            })
            (
              final: prev:
              self.packages.${system}
              // {
                github-cli-tools = self.packages.${system}.github-cli-tools;
                python313Packages = prev.python313Packages // legacyPackages.python313Packages;

                inherit (niri-float-sticky.packages.${system}) niri-float-sticky;
                wezterm = wezterm.packages.${system}.default;
              }
            )
          ];
        };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit
          (pkgsForSystem {
            pkgs = nixpkgs-unstable;
            inherit system;
          })
          pkgs
          legacyPackages
          ;
        lib = import ./lib/node.nix {
          inherit pkgs;
          inherit (pkgs) stdenv;
        };
      in
      {
        devShells = import ./shell {
          lib = pkgs.lib // lib;
          inherit pkgs;
        };

        packages = import ./package { inherit pkgs; };

        inherit legacyPackages;
      }
    )
    // (import ./system {
      inherit
        darwin
        home-manager
        lanzaboote
        niri
        nix-flatpak
        nix-on-droid
        nix-rosetta-builder
        nix-std
        nixos-hardware
        nixpkgs-unstable
        sops-nix
        pkgsForSystem
        desktopBackground
        ;
    });
}
