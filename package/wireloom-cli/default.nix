{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs) fetchPnpmDeps makeWrapper nodejs pnpm pnpmConfigHook;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "wireloom-cli";
  version = "0.1.0";

  src = ./.;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-7yXSJFkYuAfiYHllGMqOSlAe1pWStC2Ihg0dIT0M4d0=";
  };

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    nodejs
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    targetDir=$out/lib/node_modules/${finalAttrs.pname}
    mkdir -p "$targetDir"

    cp package.json index.mjs "$targetDir/"
    cp -rL node_modules "$targetDir/"

    makeWrapper ${nodejs}/bin/node $out/bin/wireloom-render \
      --add-flags "$targetDir/index.mjs"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Render Wireloom sources into a navigable SVG prototype";
    homepage = "https://github.com/StardockCorp/Wireloom";
    license = licenses.mit;
    mainProgram = "wireloom-render";
    platforms = platforms.all;
  };
})
