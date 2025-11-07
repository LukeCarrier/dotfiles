{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-brCz15UdheVf1+vU7OQw7EnElIKq8xsbV8jJ5b1HjEM==";
  };

  cargoHash = "sha256-EJPUC7xI0KKuXpua9O3bUvBbEnscRvms8gwdGkEk/Os==";

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
