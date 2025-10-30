{ pkgs }:
{
  aws-cli-tools = pkgs.callPackage ./aws-cli-tools { };

  bw-cli-tools = pkgs.callPackage ./bw-cli-tools { };

  docker-cli-tools = pkgs.callPackage ./docker-cli-tools { };

  dotfiles-meta = pkgs.callPackage ./dotfiles-meta { };

  eww-niri-workspaces = pkgs.callPackage ./eww-niri-workspaces {
    ewwNiriWorkspaces = rec {
      owner = "LukeCarrier";
      # FIXME: there are currently no tags available :-(
      rev = "refs/heads/main";
      version = "0.0.0-${rev}";
      hash = "sha256-w/qGm7eOIhN+Uzj5pFRWk3jLcL8ABo3SPzksOBtYgwM=";
      cargoHash = "sha256-45X5XrDC74znu78cKpsJ32OBpGiRNRXJ597/+c/Hcpk=";
    };
  };

  kubernetes-client-tools = pkgs.callPackage ./kubernetes-client-tools { };

  monaspace-fonts = pkgs.callPackage ./monaspace-fonts {
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

  spec-kit = pkgs.callPackage ./spec-kit { };

  stklos = pkgs.callPackage ./stklos {
    stklos =
      let
        version = "2.10";
      in
      {
        inherit version;
        url = "https://stklos.net/download/stklos-${version}.tar.gz";
        hash = "sha256-bb8DRfkgSP7GEzrW5V1x0L47d21YF0sIftCPfEsuoEE=";
      };
  };
}
