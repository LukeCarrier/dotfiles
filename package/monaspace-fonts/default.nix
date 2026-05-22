{ pkgs }:
let
  version = "1.101";
  monaspaceSrc = pkgs.fetchzip {
    url = "https://github.com/githubnext/monaspace/releases/download/v${version}/monaspace-v${version}.zip";
    hash = "sha256-o5s4XBuwqA4sJ5KhEn5oYttBj4ojekr/LO6Ww9oQRGw=";
    stripRoot = false;
  };
in
pkgs.linkFarm "monaspace-fonts" [
  {
    name = "share/fonts/truetype";
    path = "${monaspaceSrc}/monaspace-v${version}/fonts/variable";
  }
]
