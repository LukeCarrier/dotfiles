{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz";
  version = "0.4.22";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "v${finalAttrs.version}";
    hash = "sha256-MDroR4oo4F2INwMA60cZnZWsyv9fyp9Dy3i2nopf/0U=";
  };

  cargoHash = "sha256-WgiEzT59SEz150mUy+oE3jjFqOiHHKeAYQ4Yd/HwoQk=";

  cargoBuildFlags = [
    "--package"
    "buzz-cli"
  ];

  doCheck = false;

  meta = with lib; {
    description = "A workspace where humans and agents build together, on a relay you own";
    homepage = "https://buzz.xyz";
    license = licenses.asl20;
    mainProgram = "buzz";
    platforms = platforms.linux ++ platforms.darwin;
  };
})
