{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs) fetchFromGitHub;
  nodeLib = import ../../lib/node.nix { inherit pkgs stdenv; };
  inherit (nodeLib) buildPnpmPackage;
in
buildPnpmPackage rec {
  pname = "mcp-remote";
  version = "0.1.30";

  src = fetchFromGitHub {
    owner = "geelen";
    repo = "mcp-remote";
    rev = "v${version}";
    hash = "sha256-EQuiz/lygmynJjBrcAkX5MTrqYKWpD4OP4mvWZfO87s=";
  };

  pnpmDepsFetcherVersion = 1;
  pnpmDepsHash = "sha256-RLElbVkKwFo2XQur8l0zSriMUHEm3TGsW+74IVnSPa8=";

  pnpmBuildScript = "build";

  meta = with lib; {
    description = "Local proxy to connect local MCP clients to remote MCP servers";
    homepage = "https://github.com/geelen/mcp-remote";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
