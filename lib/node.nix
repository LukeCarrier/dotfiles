{ pkgs, stdenv }:
let
  inherit (pkgs) npmHooks pnpm;
  inherit (stdenv) mkDerivation;
in
{
  buildBunPackage =
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
          bun
          nodejs
        ])
        ++ (pkg.nativeBuildInputs or [ ]);

      configurePhase = ''
        runHook preConfigure
        bun install --no-progress --frozen-lockfile
        runHook postConfigure
      '';

      buildPhase = ''
        runHook preBuild
        bun run ${pkg.bunBuildScript}
        runHook postBuild
      '';

      installPhase = ''
        mkdir -p $out
        cp -r . $out/
      '';
    };

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
          pnpm
          pnpmConfigHook
          typescript
        ])
        ++ (pkg.nativeBuildInputs or [ ]);

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (pkg) pname version src;
        fetcherVersion = pkg.pnpmDepsFetcherVersion;
        hash = pkg.pnpmDepsHash;
      };

      dontNpmPrune = true;

      postBuild = ''
        pnpm run ${pkg.pnpmBuildScript}
      '';
    };
}
