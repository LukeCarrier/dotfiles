{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs) buildNpmPackage fetchFromGitHub;
  nodeLib = import ../../lib/node.nix { inherit pkgs stdenv; };
  inherit (nodeLib);
in
buildNpmPackage rec {
  pname = "excalidraw-mcp-app";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "antonpk1";
    repo = "excalidraw-mcp-app";
    rev = "v0.2.0";
    hash = "sha256-VkVNfV0EYh9FxL7F/JD3r49vXlnE4dnu9EsRjjW3yyY=";
  };

  npmDepsHash = "sha256-VgVUc4n+XXy+XxNm9dIX4Pq8bb59SexIBycgDbFx1HY=";

  # XXX: why?
  nativeBuildInputs = [ pkgs.bun ];
  makeCacheWritable = true;
  npmFlags = [ "--legacy-peer-deps" ];

  installPhase = ''
    mkdir -p $out/bin $out/lib/node_modules/${pname}
    cp -r dist $out/lib/node_modules/${pname}/
    cp package.json $out/lib/node_modules/${pname}/

    # Create executable wrapper
    cat > $out/bin/mcp-server-excalidraw <<EOF
    #!/bin/sh
    exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/${pname}/dist/index.js "\$@"
    EOF
    chmod +x $out/bin/mcp-server-excalidraw
  '';

  meta = with lib; {
    description = "Streamable Excalidraw diagram MCP App server";
    homepage = "https://github.com/antonpk1/excalidraw-mcp-app";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
