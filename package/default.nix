{ pkgs }:
let
  inherit (pkgs) callPackage;
in
{
  aws-cli-tools = callPackage ./aws-cli-tools { };

  bw-cli-tools = callPackage ./bw-cli-tools { };

  docker-cli-tools = callPackage ./docker-cli-tools { };

  dotfiles-meta = callPackage ./dotfiles-meta { };

  eww-niri-workspaces = callPackage ./eww-niri-workspaces {
    ewwNiriWorkspaces = rec {
      owner = "LukeCarrier";
      # FIXME: there are currently no tags available :-(
      rev = "refs/heads/main";
      version = "0.0.0-${rev}";
      hash = "sha256-w/qGm7eOIhN+Uzj5pFRWk3jLcL8ABo3SPzksOBtYgwM=";
      cargoHash = "sha256-45X5XrDC74znu78cKpsJ32OBpGiRNRXJ597/+c/Hcpk=";
    };
  };

  excalidraw-mcp-app = callPackage ./excalidraw-mcp-app { };

  kubernetes-client-tools = callPackage ./kubernetes-client-tools { };

  mcp-remote = callPackage ./mcp-remote { };

  monaspace-fonts = callPackage ./monaspace-fonts {
    monaspace-fonts =
      let
        version = "1.101";
      in
      {
        inherit version;
        url = "https://github.com/githubnext/monaspace/releases/download/v${version}/monaspace-v${version}.zip";
        hash = "sha256-o5s4XBuwqA4sJ5KhEn5oYttBj4ojekr/LO6Ww9oQRGw=";
      };
  };

  ocu = callPackage ./ocu {
    ocu = rec {
      owner = "jsribeiro";
      rev = "v0.2.2";
      version = "0.2.2";
      hash = "sha256-NaYgZeoPYmaTG7mBg+aVLlEzAPjHL8xXPZoqcA2/gLc=";
      cargoHash = "sha256-W5SWxG6wVgDoBPPT0mKj1HNUR9pRXzVm65yM7N49kU0=";
    };
  };

  rift = callPackage ./rift { };

  spec-kit = callPackage ./spec-kit { };

  stklos = callPackage ./stklos {
    stklos =
      let
        version = "26.0";
      in
      {
        inherit version;
        url = "https://stklos.net/download/stklos-${version}.tar.gz";
        hash = "sha256-YSTQDELOKUbRgExW7D4hclr6RYOWR1FtT7zHbf5MEow=";
      };
  };
}
