{ pkgs }:
let
  inherit (pkgs) fetchzip stdenvNoCC symlinkJoin;
  inherit (pkgs.lib) mapAttrsToList;

  version = "1.400";
  baseUrl = "https://github.com/githubnext/monaspace/releases/download/v${version}";

  variants = {
    static = {
      hash = "sha256-wbgCQQZuWU7A486z4cVS9mfWc+O5u+As23bVgUNevzw=";
      destination = "opentype";
    };
    frozen = {
      hash = "sha256-vxwVk3iVZksjYfTl2OQLvwiw6DP3aXMlM99v2f9oZ4I=";
      destination = "truetype";
    };
    variable = {
      hash = "sha256-n3SwICKrE05gwLlEskexQQoo/NVODQxwps1JVfjGGY0=";
      destination = "truetype";
    };
    nerdfonts = {
      hash = "sha256-utqL4skUY/HUASsJ9rMDPkJ0nLwLJu/ayqCk7sVJjKg=";
      destination = "opentype";
    };
    webfont-static = {
      hash = "sha256-T1etH3HllVNw0bLpqi0i4jaNvjaiUu4jk32X02wY++s=";
      destination = "woff";
    };
    webfont-nerdfonts = {
      hash = "sha256-6gjRUavugl9yGUo8vbliojV6MePeKocByiUrfeHbVLg=";
      destination = "woff";
    };
    webfont-variable = {
      hash = "sha256-BmipeKGHFaEGkNbf++Td/59Ay42/33M785aZbjrZirU=";
      destination = "woff";
    };
  };

  makeFont =
    variant: { hash, destination }:
    stdenvNoCC.mkDerivation {
      pname = "monaspace-${variant}";
      inherit version;

      src = fetchzip {
        url = "${baseUrl}/monaspace-${variant}-v${version}.zip";
        inherit hash;
      };

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/fonts/${destination}"
        find . -type f \( -name '*.otf' -o -name '*.ttf' -o -name '*.woff' -o -name '*.woff2' \) \
          -exec install -m 644 {} "$out/share/fonts/${destination}" \;

        runHook postInstall
      '';
    };
in
symlinkJoin {
  name = "monaspace-fonts";
  inherit version;

  paths = mapAttrsToList makeFont variants;
}
