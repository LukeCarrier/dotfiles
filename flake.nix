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
    asciinema = {
      url = "github:asciinema/asciinema";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    ashell = {
      url = "github:MalpenZibo/ashell/main";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };
    code-insiders = {
      url = "github:iosmanthus/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    compass = {
      url = "github:throwparty/compass?dir=nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    cyberhaven = {
      url = "github:LukeCarrier/cyberhaven-nix";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    falcon-sensor = {
      url = "github:LukeCarrier/falcon-sensor-nixos";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    handy = {
      url = "github:cjpais/handy";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        bun2nix.inputs.systems.follows = "systems";
      };
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
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nirivana = {
      url = "git+ssh://git@github.com/throwparty/nirivana?dir=nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
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
      url = "github:NixOS/nixos-hardware";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/main";
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-std.url = "github:chessai/nix-std";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
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
    shanocast = {
      url = "github:rgerganov/shanocast";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    systems = {
      url = "path:./flake.systems.nix";
      flake = false;
    };
    tardy = {
      url = "github:throwparty/tardy?dir=nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    # Deliberately not following nixpkgs: the vicinae Cachix cache is keyed to
    # the flake's own nixpkgs pin, so any override causes a cache miss.
    vicinae.url = "github:vicinaehq/vicinae";
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
      asciinema,
      ashell,
      claude-code,
      code-insiders,
      compass,
      cyberhaven,
      dagger,
      darwin,
      disko,
      falcon-sensor,
      flake-utils,
      handy,
      home-manager,
      lanzaboote,
      niri,
      nirivana,
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
      shanocast,
      sops-nix,
      wezterm,
      wpaperd,
      tardy,
      vicinae,
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
            compass.overlays.default
            dagger.overlays.default
            niri.overlays.niri
            nix-vscode-extensions.overlays.default
            nur.overlays.default
            rust-overlay.overlays.default
            tardy.overlays.default
            wpaperd.overlays.default
            (final: prev: {
              fwupd = prev.fwupd.overrideAttrs (old: {
                mesonFlags = (old.mesonFlags or []) ++ [ "-Defi_app_location=/run/fwupd-efi" ];
              });
            })
            (final: prev: {
              asciinema = asciinema.packages.${system}.default;
              ashell = ashell.packages.${system}.default.overrideAttrs (old: {
                # MalpenZibo/ashell#914: tooltips for custom modules.
                patches = (old.patches or [ ]) ++ [ ./package/ashell/pr-914.patch ];
              });
              # NixOS/nixpkgs#535887
              cantarell-fonts =
                prev.cantarell-fonts.overrideAttrs (old: {
                  nativeBuildInputs = builtins.map (
                    drv:
                    if (drv.pname or null) == "afdko" then
                      prev.python3.pkgs.afdko
                    else
                      drv
                  ) old.nativeBuildInputs;
                });

              handy = handy.packages.${system}.handy.overrideAttrs (old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ prev.wtype ];
                patches = (old.patches or [ ]) ++ [ ./package/handy/pr-1337.patch ];
              });
              niri = niri.packages.${system}.niri-unstable.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [
                  # niri-wm/niri#1791: SHM screencast fallback, needed for
                  # GStreamer pipewiresrc (GNOME Network Displays) to negotiate
                  # a buffer format at all under niri's DMA-BUF-only export.
                  ./package/niri/pr-1791.patch
                  # niri-wm/niri#4382: column navigation with trackpoint
                  # swipe gestures.
                  ./package/niri/pr-4382.patch
                ];
              });
            })
            (
              final: prev:
              let
                callPackage' = prev.callPackage;
                aws-cli-tools = callPackage' ./package/aws-cli-tools { };
                buzz-acp = callPackage' ./package/buzz/acp.nix { };
                buzz-agent = callPackage' ./package/buzz/agent.nix { };
                buzz-cli = callPackage' ./package/buzz/cli.nix { };
                buzz-dev-mcp = callPackage' ./package/buzz/dev-mcp.nix { };
                buzz-desktop = callPackage' ./package/buzz/desktop.nix {
                  inherit buzz-acp buzz-agent buzz-cli buzz-dev-mcp git-credential-nostr;
                };
                buzz-relay = callPackage' ./package/buzz/relay.nix { };
                git-credential-nostr = callPackage' ./package/buzz/git-credential-nostr.nix { };
                bw-cli-tools = callPackage' ./package/bw-cli-tools { };
                docker-cli-tools = callPackage' ./package/docker-cli-tools { };
                github-cli-tools = callPackage' ./package/github-cli-tools { };
                dotfiles-meta = callPackage' ./package/dotfiles-meta { };
                eww-niri-workspaces = callPackage' ./package/eww-niri-workspaces { };
                excalidraw-mcp-app = callPackage' ./package/excalidraw-mcp-app { };
                ghidra-mcp = callPackage' ./package/ghidra-mcp { };
                ghidra-mcp-plugin = (callPackage' ./package/ghidra-mcp { }).ghidraPlugin;
                goose-cli = callPackage' ./package/goose/goose.nix { };
                goose-desktop = callPackage' ./package/goose/desktop.nix { inherit goose-cli; };
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
                toon-cli = callPackage' ./package/toon-cli { };
                wireloom-cli = callPackage' ./package/wireloom-cli { };
              in
              {
                aws-cli-tools = aws-cli-tools;
                buzz-cli = buzz-cli;
                buzz-desktop = buzz-desktop;
                buzz-relay = buzz-relay;
                bw-cli-tools = bw-cli-tools;
                docker-cli-tools = docker-cli-tools;
                github-cli-tools = github-cli-tools;
                dotfiles-meta = dotfiles-meta;
                eww-niri-workspaces = eww-niri-workspaces;
                excalidraw-mcp-app = excalidraw-mcp-app;
                ghidra-mcp = ghidra-mcp;
                ghidra-mcp-plugin = ghidra-mcp-plugin;
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
                toon-cli = toon-cli;
                wireloom-cli = wireloom-cli;

                niri-float-sticky = niri-float-sticky.packages.${system}.niri-float-sticky;

                shanocast = shanocast.packages.${system}.default;

                wezterm = wezterm.packages.${system}.default;
              }
            )
            # eMed security agents overlays are applied by the respective nixos
            # modules (falcon-sensor, cyberhaven). The -unwrapped derivations are
            # overridden per-host via employer/emed/nixos.nix.
          ];

          mergedConfig = config // {
            allowAliases = false;
            allowUnfreePredicate =
              pkg:
              builtins.elem (pkgs.lib.getName pkg) flakeUnfree || (config.allowUnfreePredicate or (_: false)) pkg;
            permittedInsecurePackages = permittedInsecurePackages ++ (config.permittedInsecurePackages or [ ]);
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
        pkgs = pkgsForSystem {
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
        cyberhaven
        darwin
        disko
        falcon-sensor
        home-manager
        lanzaboote
        niri
        nirivana
        nix-flatpak
        nix-on-droid
        nix-rosetta-builder
        nixos-hardware
        nixpkgs-unstable
        sops-nix
        vicinae
        pkgsForSystem
        desktopBackground
        permittedInsecurePackages
        ;
    });
}
