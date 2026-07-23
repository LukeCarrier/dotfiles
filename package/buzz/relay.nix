{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz-relay";
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
    "buzz-relay"
  ];

  doCheck = false;

  meta = with lib; {
    description = "WebSocket relay server for the Buzz communications platform";
    homepage = "https://buzz.xyz";
    license = licenses.asl20;
    mainProgram = "buzz-relay";
    platforms = platforms.linux;
  };
})
