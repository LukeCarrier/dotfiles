{
  lib,
  rustPlatform,
  fetchFromGitHub,
  ocu,
}:
rustPlatform.buildRustPackage rec {
  pname = "ocu";
  version = ocu.version;

  src = fetchFromGitHub {
    owner = ocu.owner;
    repo = "opencode-usage-companion";
    rev = ocu.rev;
    hash = ocu.hash;
  };

  cargoHash = ocu.cargoHash;

  meta = with lib; {
    description = "A fast, cross-platform Rust CLI tool that queries AI provider quotas and usage by reusing existing OpenCode authentication tokens";
    homepage = "https://github.com/jsribeiro/opencode-usage-companion";
    license = licenses.gpl3Only;
    mainProgram = "ocu";
  };
}
