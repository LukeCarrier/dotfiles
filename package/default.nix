{ pkgs }:
let
  inherit (pkgs) callPackage;
  obsbot-camera-control = callPackage ./obsbot-camera-control { };
in
rec {
  aws-cli-tools = callPackage ./aws-cli-tools { };

  bw-cli-tools = callPackage ./bw-cli-tools { };

  docker-cli-tools = callPackage ./docker-cli-tools { };

  github-cli-tools = callPackage ./github-cli-tools { };

  dotfiles-meta = callPackage ./dotfiles-meta { };

  eww-niri-workspaces = callPackage ./eww-niri-workspaces { };

  excalidraw-mcp-app = callPackage ./excalidraw-mcp-app { };

  ghidra-mcp = callPackage ./ghidra-mcp { };
  ghidra-mcp-plugin = (callPackage ./ghidra-mcp { }).ghidraPlugin;

  goose-server = callPackage ./goose/goose.nix { gooseBin = "goosed"; };
  goose-cli = callPackage ./goose/goose.nix { gooseBin = "goose"; };
  goose-desktop = callPackage ./goose/desktop.nix { inherit goose-server; };

  grafana-mcp = callPackage ./grafana-mcp { };

  hibiki = callPackage ./hibiki { };

  kubernetes-client-tools = callPackage ./kubernetes-client-tools { };

  mcp-remote = callPackage ./mcp-remote { };

  monaspace-fonts = callPackage ./monaspace-fonts { };

  inherit (obsbot-camera-control)
    obsbot-sdk
    obsbot-camera-control-cli
    obsbot-camera-control-gui;

  ocu = callPackage ./ocu { };

  rift = callPackage ./rift { };

  spec-kit = callPackage ./spec-kit { };

  stklos = callPackage ./stklos { };
}
