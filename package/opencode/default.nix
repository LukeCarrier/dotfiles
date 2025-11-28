{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "opencode";
  version = "1.0.119";

  src = fetchFromGitHub {
    owner = "sst";
    repo = "opencode";
    rev = "v${version}";
    hash = "sha256-PLACEHOLDER_SRCHASHERE";
  };

  vendorHash = "sha256-PLACEHOLDER_VENDORHASHHERE";

  meta = with lib; {
    description = "The best coding agent on the planet";
    homepage = "https://github.com/sst/opencode";
    license = licenses.mit;
    mainProgram = "opencode";
  };
}
