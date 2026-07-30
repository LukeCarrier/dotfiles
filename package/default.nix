{ pkgs }:
let
  inherit (pkgs) callPackage;
  obsbot-camera-control = callPackage ./obsbot-camera-control { };

  buzzAcp = callPackage ./buzz/acp.nix { };
  buzzAgent = callPackage ./buzz/agent.nix { };
  buzzCli = callPackage ./buzz/cli.nix { };
  buzzDevMcp = callPackage ./buzz/dev-mcp.nix { };
  gitCredentialNostr = callPackage ./buzz/git-credential-nostr.nix { };
in
rec {
  aws-cli-tools = callPackage ./aws-cli-tools { };

  buzz-acp = buzzAcp;
  buzz-agent = buzzAgent;
  buzz-cli = buzzCli;
  buzz-dev-mcp = buzzDevMcp;
  git-credential-nostr = gitCredentialNostr;

  buzz-desktop = callPackage ./buzz/desktop.nix {
    "buzz-acp" = buzzAcp;
    "buzz-agent" = buzzAgent;
    "buzz-cli" = buzzCli;
    "buzz-dev-mcp" = buzzDevMcp;
    "git-credential-nostr" = gitCredentialNostr;
  };

  bw-cli-tools = callPackage ./bw-cli-tools { };

  docker-cli-tools = callPackage ./docker-cli-tools { };

  github-cli-tools = callPackage ./github-cli-tools { };

  dotfiles-meta = callPackage ./dotfiles-meta { };

  eww-niri-workspaces = callPackage ./eww-niri-workspaces { };

  excalidraw-mcp-app = callPackage ./excalidraw-mcp-app { };

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

  inherit (obsbot-camera-control)
    obsbot-sdk
    obsbot-camera-control-cli
    obsbot-camera-control-gui;

  ocu = callPackage ./ocu { };

  onepassword-tools = callPackage ./onepassword-tools { };

  openwarp = callPackage ./openwarp { };

  rift = callPackage ./rift { };

  spec-kit = callPackage ./spec-kit { };

  stklos = callPackage ./stklos { };

  toon-cli = callPackage ./toon-cli { };
}
