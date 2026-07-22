{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz";
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
