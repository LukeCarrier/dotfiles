{
  goose-server,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pkgs,
  ...
}:
let
  inherit (lib) getExe optionalString;
  inherit (pkgs) electron makeDesktopItem;
  version = "1.35.0";
  rawSrc = fetchFromGitHub {
    owner = "aaif-goose";
    repo = "goose";
    tag = "v${version}";
    sha256 = "sha256-phcv0quM9eZoHE1qYZ6RsXb6irWDRRpPJwEGlRDwAvM=";
  };
  src = stdenv.mkDerivation (finalAttrs: {
    pname = "goose-desktop";
    inherit version;
    src = rawSrc;
    patches = [
      ./patches/0001-chore-deps-don-t-block-exotic-subdeps.patch
      ./patches/0002-chore-deps-allow-builds.patch
      ./patches/0003-chore-deps-relocate-overrides.patch
      ./patches/0004-chore-deps-use-hoisted-linker-for-electron-forge.patch
    ];
    buildPhase = "true";
    installPhase = ''
      cp -a . $out
      find $out -type l ! -exec test -e {} \; -delete
    '';
  });

  pnpm = pkgs.pnpm_11;
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
    hash = "sha256-Y+jfxYjREf+RzZNl8yEOOhtwioA6f01G+Dofp2/up64=";
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
    node ../node_modules/@electron-forge/cli/dist/electron-forge.js package
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
