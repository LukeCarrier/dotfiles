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
stdenv.mkDerivation (finalAttrs: rec {
  pname = "mcp-remote";
  version = "0.14.2";

  src = fetchFromGitHub {
    owner = "punkpeye";
    repo = "mcp-remote";
    rev = "v${version}";
    hash = "sha256-b3IEAVwxTb2c/2ENRgQqluuZ5BE3alXsqProDwWQ1eA=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-h1Rh3xDw6mpCBWfh+fjfWtZ8WrdziEL2d6S+k9VaghQ=";
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

    cp -r dist "$targetDir/"
    cp package.json "$targetDir/"

    cp -rL node_modules "$targetDir/"

    makeWrapper ${nodejs}/bin/node $out/bin/mcp-remote-client \
      --add-flags "$targetDir/bin/client.js"
    makeWrapper ${nodejs}/bin/node $out/bin/mcp-remote-proxy \
      --add-flags "$targetDir/bin/proxy.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Local proxy to connect local MCP clients to remote MCP servers";
    homepage = "https://github.com/punkpeye/mcp-remote";
    license = licenses.mit;
    platforms = platforms.all;
  };
})
