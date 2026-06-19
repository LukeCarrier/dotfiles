{ pkgs, stdenv }:
let
  inherit (pkgs) fetchPnpmDeps npmHooks;
  inherit (stdenv) mkDerivation;

  # On macOS arm64, Worker threads default to trackUnmanagedFds: true. pnpm's
  # graceful-fs EAGAIN retry loop causes fd churn; fd numbers get recycled by
  # libuv for internal pipes. When Workers exit, Node.js cleanup closes all
  # tracked-but-unclosed fds — which now belong to libuv internals — causing a
  # crash that presents as SIGKILL (exit code 137) during `pnpm install`.
  # Fix: disable trackUnmanagedFds on the WorkerPool constructor.
  # See https://github.com/nodejs/node/commit/7603c7e50c
  pnpm = pkgs.pnpm.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace dist/pnpm.mjs \
        --replace-fail \
          'resourceLimits: this._workerResourceLimits' \
          'resourceLimits: this._workerResourceLimits, trackUnmanagedFds: false'
    '';
  });
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
        [ pnpm ]
        ++ (with pkgs; [
          nodejs
          npmHooks.npmInstallHook
          pnpmConfigHook
          typescript
        ])
        ++ (pkg.nativeBuildInputs or [ ]);

      pnpmDeps = fetchPnpmDeps {
        inherit (pkg) pname version src;
        inherit pnpm;
        fetcherVersion = pkg.pnpmDepsFetcherVersion;
        hash = pkg.pnpmDepsHash;
      };

      dontNpmPrune = true;

      postBuild = ''
        pnpm run ${pkg.pnpmBuildScript}
      '';
    };
}
