{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-Xot9yE0z/X2wcTtF+HkDnCUCbpkj8TT+sAVErKY2UAg=";
  };

  cargoHash = "sha256-A0huWauj3Ltnw39jFft6pyYUVcNK+lu89ZlVQl/aRZg=";

  # acsandmann/rift#11
  doCheck = true;

  meta = with lib; {
    description = "A tiling window manager for macOS";
    homepage = "https://github.com/acsandmann/rift";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "rift";
  };
}
