{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "git-credential-nostr";
  version = "0.4.23";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "v${finalAttrs.version}";
    hash = "sha256-gxjoDvfKj0UhHZfOVSO0UZBx31oZJVXThgYGPRtjiPU=";
  };

  cargoHash = "sha256-WXnmAsFo5m9mZGy7gLk6egTN94X7WMSsBfhslzaloH4=";

  cargoBuildFlags = [
    "--package"
    "git-credential-nostr"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Git credential helper for NIP-98 auth to Buzz relays";
    homepage = "https://buzz.xyz";
    license = licenses.asl20;
    mainProgram = "git-credential-nostr";
    platforms = platforms.linux ++ platforms.darwin;
  };
})
