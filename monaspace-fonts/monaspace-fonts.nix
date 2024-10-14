{ monaspace-fonts, lib, pkgs }:
let monaspaceSrc = pkgs.fetchzip {
  url = monaspace-fonts.url;
  sha256 = monaspace-fonts.sha256;
  stripRoot = false;
};
in
  pkgs.linkFarm "monaspace-fonts" [
    {
      name = "share/fonts/truetype";
      path = "${monaspaceSrc}/monaspace-v${monaspace-fonts.version}/fonts/variable";
    }
  ]
