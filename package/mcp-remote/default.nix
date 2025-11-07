{
  lib,
  pkgs,
  stdenv,
}:
let
  inherit (pkgs) fetchFromGitHub npmHooks pnpm;
  inherit (stdenv) mkDerivation;
  buildPnpmPackage =
    pkg:
    mkDerivation {
      inherit (pkg)
        pname
        version
        src
        meta
        ;

      nativeBuildInputs =
        (with pkgs; [
          nodejs
          npmHooks.npmInstallHook
          pnpm.configHook
          typescript
        ])
        ++ (pkg.nativeBuildInputs or [ ]);

      pnpmDeps = pnpm.fetchDeps {
        inherit (pkg) pname version src;
        fetcherVersion = pkg.pnpmDepsFetcherVersion;
        hash = pkg.pnpmDepsHash;
      };
      dontNpmPrune = true;

      postBuild = ''
        pnpm run ${pkg.pnpmBuildScript}
      '';
    };
in
buildPnpmPackage rec {
  pname = "mcp-remote";
  version = "0.1.30";

  src = fetchFromGitHub {
    owner = "geelen";
    repo = "mcp-remote";
    rev = "v${version}";
    sha256 = "sha256-EQuiz/lygmynJjBrcAkX5MTrqYKWpD4OP4mvWZfO87s=";
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
