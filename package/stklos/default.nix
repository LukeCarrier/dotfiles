{
  pkgs,
  fetchurl,
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "stklos";
  version = "26.0";

  src = fetchurl {
    url = "https://stklos.net/download/stklos-${finalAttrs.version}.tar.gz";
    hash = "sha256-YSTQDELOKUbRgExW7D4hclr6RYOWR1FtT7zHbf5MEow=";
  };

  postPatch = ''
    grep -Rl '/bin/rm' . | while read -r file; do
      substituteInPlace "$file" --replace '/bin/rm' 'rm'
    done
  '';

  nativeBuildInputs = [ pkgs.automake116x pkgs.automake pkgs.autoconf pkgs.m4 ];

  configureFlags = [ ];

  hardeningDisable = [ ];
})
