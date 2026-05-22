{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ocu";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "jsribeiro";
    repo = "opencode-usage-companion";
    rev = "v${finalAttrs.version}";
    hash = "sha256-NaYgZeoPYmaTG7mBg+aVLlEzAPjHL8xXPZoqcA2/gLc=";
  };

  cargoHash = "sha256-W5SWxG6wVgDoBPPT0mKj1HNUR9pRXzVm65yM7N49kU0=";

  meta = with lib; {
    description = "A fast, cross-platform Rust CLI tool that queries AI provider quotas and usage by reusing existing OpenCode authentication tokens";
    homepage = "https://github.com/jsribeiro/opencode-usage-companion";
    license = licenses.gpl3Only;
    mainProgram = "ocu";
  };
})
