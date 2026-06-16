{
  goose-server,
  lib,
  stdenv,
  fetchFromGitHub,
  pkgs,
  ...
}:
let
  inherit (lib) getExe optionalString;
  inherit (pkgs) electron makeDesktopItem;
  fetchPnpmDeps = (pkgs.callPackage ./fetch-pnpm-deps/default.nix { }).fetchPnpmDeps;
  version = "1.38.0";
  rawSrc = fetchFromGitHub {
    owner = "aaif-goose";
    repo = "goose";
    tag = "v${version}";
    sha256 = "sha256-bR38jxh379Rp9ZU6Hd+1aKDl+88UkmWF/niwp8uB3aE=";
  };
  src = stdenv.mkDerivation (finalAttrs: {
    pname = "goose-desktop";
    inherit version;
    src = rawSrc;
    patches = [
      ./patches/0001-chore-deps-allow-builds.patch
      ./patches/0002-chore-deps-relocate-overrides.patch
      ./patches/0003-chore-deps-use-hoisted-linker-for-electron-forge.patch
    ];
    buildPhase = "true";
    installPhase = ''
      cp -a . $out
      find $out -type l ! -exec test -e {} \; -delete
    '';
  });

  pnpm = pkgs.pnpm_11.overrideAttrs (_: {
    version = "11.5.2";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/pnpm/-/pnpm-11.5.2.tgz";
      hash = "sha256-dJ3FT709zenkFLquMsF3yoR3DT/NaciBbVea3D5qLJk=";
    };
    # On macOS arm64, Worker threads default to trackUnmanagedFds: true.
    # pnpm's graceful-fs EAGAIN retry loop causes fd churn; fd numbers get
    # recycled by libuv for internal pipes. When Workers exit, Node.js cleanup
    # closes all tracked-but-unclosed fds — which now belong to libuv internals
    # — causing a crash that presents as SIGKILL.
    # Fix: disable trackUnmanagedFds on the WorkerPool constructor.
    # See https://github.com/nodejs/node/commit/7603c7e50c
    postPatch = ''
      substituteInPlace dist/pnpm.mjs \
        --replace-fail \
          'resourceLimits: this._workerResourceLimits' \
          'resourceLimits: this._workerResourceLimits, trackUnmanagedFds: false'
    '';
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "goose-desktop";
  inherit version src;

  pnpmRoot = "ui";
  pnpmDeps = fetchPnpmDeps {
    pname = finalAttrs.pname;
    inherit version pnpm;
    src = "${src}/ui";
    fetcherVersion = 3;
    hash = "sha256-nEUwkk42OEhDftzoX4KG5X7nuDq+pO8U7zckMdwnE8A=";
  };

  nativeBuildInputs =
    [ pnpm ]
    ++ (with pkgs; [
      nodejs
      pnpmConfigHook
      zip
      copyDesktopItems
      makeWrapper
    ]);

  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  buildPhase = ''
    runHook preBuild
    pushd ui

    # Disable ad-hoc Darwin re-signing: codesign is unavailable in the Nix sandbox
    substituteInPlace desktop/forge.config.ts \
      --replace-fail \
        "new FusesPlugin({" \
        "new FusesPlugin({ resetAdHocDarwinSignature: false,"

    # Patch electron-forge to use our electron distribution
    substituteInPlace node_modules/@electron-forge/core-utils/dist/electron-version.js \
      --replace-fail "return version" "return '${electron.version}'"
    substituteInPlace \
      node_modules/@electron/packager/dist/packager.js \
      --replace-fail "await this.getElectronZipPath(downloadOpts)" "'$(pwd)/electron.zip'"

    # Create electron zip from our electron distribution
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
    pushd electron-dist
    zip -0Xqr ../electron.zip .
    popd
    rm -r electron-dist

    pushd sdk
    pnpm run build
    popd

    pushd desktop
    # Build the application
    pnpm run i18n:compile
    # Compile SDK so electron-forge can resolve its exports (dist/index.js doesn't exist otherwise)
    # Unrolled the package target, else we need to patchShebangs and patch
    # electron-forge to fix package.json resolution.
    env DEBUG='electron-forge:*' node ../node_modules/@electron-forge/cli/dist/electron-forge.js package
    popd

    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cd ui/desktop

    mkdir -p $out/share
    mv out/Goose-* $out/share/goose-desktop

    ${optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p $out/bin
      makeWrapper ${getExe electron} "$out/bin/goose-desktop" \
         --add-flags "$out/share/goose-desktop/resources/app.asar" \
         --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
         --set-default GOOSED_BINARY ${getExe goose-server}

      install -Dm644 src/images/icon.svg "$out/share/icons/hicolor/scalable/apps/goose.svg"
    ''}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Goose";
      desktopName = "Goose";
      exec = "goose-desktop %U";
      terminal = false;
      icon = "goose";
      startupWMClass = "goose";
      comment = "";
      mimeTypes = [ "x-scheme-handler/goose" ];
      categories = [ "Development" ];
    })
  ];

  meta = {
    description = "Goose desktop application";
    homepage = "https://github.com/aaif-goose/goose";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
