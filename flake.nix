{
  description = "Luke Carrier's dotfiles";

  inputs = {
    agentkit = {
      url = "github:throwparty/agentkit?dir=nix";
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
      permittedInsecurePackages = [ "electron-39.8.10" ];
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
          overlays = [
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
              handy = handy.packages.${system}.handy.overrideAttrs (old: {
                buildInputs = (old.buildInputs or []) ++ [ prev.wtype ];
                patches = (old.patches or []) ++ [ ./package/handy/pr-1337.patch ];
              });
              niri = niri.packages.${system}.niri-unstable;
            })
            (
              final: prev:
              let
                callPackage' = prev.callPackage;
                aws-cli-tools = callPackage' ./package/aws-cli-tools { };
                bw-cli-tools = callPackage' ./package/bw-cli-tools { };
                docker-cli-tools = callPackage' ./package/docker-cli-tools { };
                github-cli-tools = callPackage' ./package/github-cli-tools { };
                dotfiles-meta = callPackage' ./package/dotfiles-meta { };
                eww-niri-workspaces = callPackage' ./package/eww-niri-workspaces { };
                excalidraw-mcp-app = callPackage' ./package/excalidraw-mcp-app { };
                ghidra-mcp = callPackage' ./package/ghidra-mcp { };
                ghidra-mcp-plugin = (callPackage' ./package/ghidra-mcp { }).ghidraPlugin;
                goose-server = callPackage' ./package/goose/goose.nix { gooseBin = "goosed"; };
                goose-cli = callPackage' ./package/goose/goose.nix { gooseBin = "goose"; };
                goose-desktop = callPackage' ./package/goose/desktop.nix { inherit goose-server; };
                grafana-mcp = callPackage' ./package/grafana-mcp { };
                hibiki = callPackage' ./package/hibiki { };
                kubernetes-client-tools = callPackage' ./package/kubernetes-client-tools { };
                mcp-remote = callPackage' ./package/mcp-remote { };
                monaspace-fonts = callPackage' ./package/monaspace-fonts { };
                obsbot-camera-control = callPackage' ./package/obsbot-camera-control { };
                ocu = callPackage' ./package/ocu { };
                onepassword-tools = callPackage' ./package/onepassword-tools { };
                rift = callPackage' ./package/rift { };
                spec-kit = callPackage' ./package/spec-kit { };
                stklos = callPackage' ./package/stklos { };
              in
              {
                aws-cli-tools = aws-cli-tools;
                bw-cli-tools = bw-cli-tools;
                docker-cli-tools = docker-cli-tools;
                github-cli-tools = github-cli-tools;
                dotfiles-meta = dotfiles-meta;
                eww-niri-workspaces = eww-niri-workspaces;
                excalidraw-mcp-app = excalidraw-mcp-app;
                ghidra-mcp = ghidra-mcp;
                ghidra-mcp-plugin = ghidra-mcp-plugin;
                goose-server = goose-server;
                goose-cli = goose-cli;
                goose-desktop = goose-desktop;
                grafana-mcp = grafana-mcp;
                hibiki = hibiki;
                kubernetes-client-tools = kubernetes-client-tools;
                mcp-remote = mcp-remote;
                monaspace-fonts = monaspace-fonts;
                obsbot-camera-control-obsbot-sdk = (obsbot-camera-control.override { }).obsbot-sdk;
                obsbot-camera-control-cli = (obsbot-camera-control.override { }).obsbot-camera-control-cli;
                obsbot-camera-control-gui = (obsbot-camera-control.override { }).obsbot-camera-control-gui;
                ocu = ocu;
                onepassword-tools = onepassword-tools;
                rift = rift;
                spec-kit = spec-kit;
                stklos = stklos;

                niri-float-sticky =
                  niri-float-sticky.packages.${system}.niri-float-sticky;

                wezterm =
                  wezterm.packages.${system}.default;
              }
            )
          ];

          mergedConfig = config // {
            allowUnfreePredicate =
              pkg:
              builtins.elem (pkgs.lib.getName pkg) flakeUnfree
              || (config.allowUnfreePredicate or (_: false)) pkg;
            permittedInsecurePackages =
              permittedInsecurePackages
              ++ (config.permittedInsecurePackages or [ ]);
          };
        in
        import pkgs {
          config = mergedConfig;
          inherit system overlays;
        };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs =
          pkgsForSystem {
            pkgs = nixpkgs-unstable;
            inherit system;
          };
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
        permittedInsecurePackages
        ;
    });
}
