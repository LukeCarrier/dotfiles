{ monaspace-fonts, pkgs }:
let
  monaspaceSrc = pkgs.fetchzip {
    url = monaspace-fonts.url;
    hash = monaspace-fonts.hash;
    stripRoot = false;
  };
in
pkgs.linkFarm "monaspace-fonts" [
  {
    name = "share/fonts/truetype";
    path = "${monaspaceSrc}/monaspace-v${monaspace-fonts.version}/fonts/variable";
  }
]
