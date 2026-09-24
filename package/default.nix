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

  floww = callPackage ./floww { };

  ghidra-mcp = callPackage ./ghidra-mcp { };
  ghidra-mcp-plugin = (callPackage ./ghidra-mcp { }).ghidraPlugin;

  goose-cli = callPackage ./goose/goose.nix { };
  goose-desktop = callPackage ./goose/desktop.nix { inherit goose-cli; };

  grafana-mcp = callPackage ./grafana-mcp { };

  hibiki = callPackage ./hibiki { };

  kubernetes-client-tools = callPackage ./kubernetes-client-tools { };

  mcp-remote = callPackage ./mcp-remote { };

  monaspace-fonts = callPackage ./monaspace-fonts { };

  inherit (pkgs) niri;

  nx-tools = callPackage ./nx-tools { };

  inherit (obsbot-camera-control)
    obsbot-sdk
    obsbot-camera-control-cli
    obsbot-camera-control-gui;

  onepassword-tools = callPackage ./onepassword-tools { };

  rift = callPackage ./rift { };

  stklos = callPackage ./stklos { };

  toon-cli = callPackage ./toon-cli { };

  wireloom-cli = callPackage ./wireloom-cli { };
}
