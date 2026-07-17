{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs) fetchFromGitHub stdenv;
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

  pnpmDepsFetcherVersion = 4;
  pnpmDepsHash = "sha256-a9hc2U1bKWsqsEUpYvw2IY/mcy4d7iPVgl/tUHUg1rk=";

  pnpmBuildScript = "build";

  meta = with lib; {
    description = "Local proxy to connect local MCP clients to remote MCP servers";
    homepage = "https://github.com/geelen/mcp-remote";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
