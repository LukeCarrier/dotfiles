{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs)
    fetchFromGitHub
    fetchPnpmDeps
    makeWrapper
    nodejs
    pnpm
    pnpmConfigHook
    ;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "toon-cli";
  version = "4.1.1";

  src = fetchFromGitHub {
    owner = "toon-format";
    repo = "toon";
    rev = "v${finalAttrs.version}";
    hash = "sha256-jTr5YSRdIDRC2lSwRp5iZGG3O7OAutZNag5MgZQHUr4=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-1UzOVz6uaU2eHPYGhIfkooZf8SPpV5SIzg8cfga158Q=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpm
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    targetDir=$out/lib/node_modules/${finalAttrs.pname}
    mkdir -p "$targetDir"

    cp -r packages/cli/dist "$targetDir/"
    cp -r packages/cli/bin "$targetDir/"
    cp packages/cli/package.json "$targetDir/"

    cp -rL packages/cli/node_modules "$targetDir/"

    makeWrapper ${nodejs}/bin/node $out/bin/toon \
      --add-flags "$targetDir/bin/toon.mjs"

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI for JSON ↔ TOON conversion using @toon-format/toon";
    homepage = "https://toonformat.dev";
    license = licenses.mit;
    mainProgram = "toon";
    platforms = platforms.all;
  };
})
