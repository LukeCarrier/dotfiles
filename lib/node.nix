{ pkgs, stdenv }:
let
  inherit (pkgs) fetchPnpmDeps npmHooks;
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
}
