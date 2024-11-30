{ pkgs, fetchurl, stklos }:
pkgs.stdenv.mkDerivation {
  pname = "stklos";
  version = stklos.version;

  src = fetchurl {
    url = stklos.url;
    hash = stklos.hash;
  };

  postPatch = ''
    grep -Rl '/bin/rm' . | while read -r file; do
      substituteInPlace "$file" --replace '/bin/rm' 'rm'
    done
  '';

  buildInputs = [];

  configureFlags = [];

  hardeningDisable = [];
}
