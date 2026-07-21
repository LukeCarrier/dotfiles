{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs) fetchFromGitHub fetchPnpmDeps makeWrapper nodejs pnpmConfigHook;
  pnpm = pkgs.pnpm_11.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace dist/pnpm.mjs \
        --replace-fail \
          'resourceLimits: this._workerResourceLimits' \
          'resourceLimits: this._workerResourceLimits, trackUnmanagedFds: false'
    '';
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "toon-cli";
  version = "2.3.1";

  src = fetchFromGitHub {
    owner = "toon-format";
    repo = "toon";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PTv7qTOjGmDAfSS4wFB22W3rV4XBPvwX7tSfreTNY2E=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-wEQY1v3fzMmt7farhbz3J1q41ACamrVicg5wHVvh7qU=";
  };

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    nodejs
    makeWrapper
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
