{ stdenv, fetchurl, pkgs, stklos }:
stdenv.mkDerivation rec {
  pname = "stklos";
  version = stklos.version;

  src = fetchurl {
    url = stklos.url;
    sha256 = stklos.sha256;
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
