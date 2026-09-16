{
  lib,
  pkgs,
}:
let
  inherit (pkgs) buildNpmPackage fetchFromGitHub;
in
buildNpmPackage rec {
  pname = "excalidraw-mcp-app";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "excalidraw";
    repo = "excalidraw-mcp";
    rev = "v0.3.2";
    hash = "sha256-Uh/sfRNnwUb1sy/PwGxyrTy/7g0cpCx9eSmwU49rFnc=";
  };

  patches = [ ./package-lock-upgrade.patch ];

  npmDepsHash = "sha256-sal8OWngt1yQ7LtZAzgVegKM9vGwHaz8NndbsWqr6m4=";

  nativeBuildInputs = [ pkgs.bun ];
  # makeCacheWritable = true;
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
