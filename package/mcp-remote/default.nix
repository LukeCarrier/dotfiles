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
    hash = "sha256-TOraN9vdVwC7XxzNV7RZt2f5hTKeFexkIZn5EYebSQA=";
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

    cp -r node_modules "$targetDir/"

    makeWrapper ${nodejs}/bin/node $out/bin/mcp-remote-client \
      --add-flags "$targetDir/dist/client.js"
    makeWrapper ${nodejs}/bin/node $out/bin/mcp-remote-proxy \
      --add-flags "$targetDir/dist/proxy.js"
    ln -s mcp-remote-proxy $out/bin/mcp-remote

    runHook postInstall
  '';

  meta = with lib; {
    description = "Local proxy to connect local MCP clients to remote MCP servers";
    homepage = "https://github.com/punkpeye/mcp-remote";
    license = licenses.mit;
    mainProgram = "mcp-remote";
    platforms = platforms.all;
  };
})
