{
  description = "Luke Carrier's dotfiles";

  inputs = {
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
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    opencode = {
      url = "github:sst/opencode/dev";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/main";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      claude-code,
      code-insiders,
      dagger,
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
      opencode,
      rust-overlay,
      sops-nix,
      wezterm,
      self,
      ...
    }:
    let
      desktopBackground = "~/Pictures/Wallpaper/Monochromatic mountains.jpg";
      pkgsForSystem =
        { pkgs, system }:
        let
          basePkgs = import pkgs { inherit system; };
          legacyPackages = import ./package/legacy-packages.nix { pkgs = basePkgs; };
        in
        {
          inherit legacyPackages;
          pkgs = basePkgs.appendOverlays [
            claude-code.overlays.default
            code-insiders.overlays.default
            dagger.overlays.default
            niri.overlays.niri
            nix-vscode-extensions.overlays.default
            nur.overlays.default
            rust-overlay.overlays.default
            (final: prev: {
              niri = niri.packages.${system}.niri-unstable;
              opencode = opencode.packages.${system}.default;
            })
            # https://github.com/NixOS/nixpkgs/pull/463322
            (final: prev: {
              ollama = prev.ollama.overrideAttrs (oldAttrs: {
                npmDeps = prev.fetchNpmDeps {
                  src = "${oldAttrs.src}/app/ui/app";
                  hash = "sha256-VokHB501c8GJVqPcBEN+x3lOR161e4VCPg1ggbNJCP0=";
                };
                npmRoot = "app/ui/app";
                nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
                  prev.nodejs
                  prev.npmHooks.npmConfigHook
                ];
                preBuild = ''
                  pushd app/ui/app
                  npm run build
                  popd
                ''
                + (oldAttrs.preBuild or "");
              });
            })
            (final: prev: {
              inherit (self.packages.${system})
                aws-cli-tools
                bw-cli-tools
                docker-cli-tools
                dotfiles-meta
                eww-niri-workspaces
                kubernetes-client-tools
                mcp-remote
                monaspace-fonts
                rift
                spec-kit
                stklos
                ;
              python313Packages = prev.python313Packages // legacyPackages.python313Packages;
              wezterm = wezterm.packages.${system}.default;
            })
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
      in
      {
        devShells = import ./shell { inherit pkgs; };

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
        nixos-hardware
        nixpkgs-unstable
        sops-nix
        pkgsForSystem
        desktopBackground
        ;
    });
}
