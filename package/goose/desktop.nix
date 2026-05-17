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
  inherit (lib) getExe makeBinPath optionalString;
  inherit (pkgs) electron makeDesktopItem;
  version = "1.34.0";
  rawSrc = fetchFromGitHub {
    owner = "aaif-goose";
    repo = "goose";
    tag = "v${version}";
    sha256 = "sha256-Ed85tMysd31aiXnUaymTmtPgh4x4urtyUsDOnh+qMks=";
  };
  # We need to patch the pnpm configuration and workspace before fetching deps,
  # and we need those same files during the build, else the lockfile will be
  # considered stale.
  src = stdenv.mkDerivation (finalAttrs: {
    pname = "goose-desktop";
    inherit version;

    src = rawSrc;
    # Of course we checked in stale lock files!
    patches = [
      ./patches/0001-chore-deps-don-t-block-exotic-subdeps.patch
      ./patches/0002-chore-deps-allow-builds.patch
      ./patches/0003-chore-deps-relocate-overrides.patch
      ./patches/0004-chore-deps-use-hoisted-linker-for-electron-forge.patch
      ./patches/0005-chore-deps-fix-up-lock-file.patch
    ];

    buildPhase = "true";

    installPhase = ''
      cp -a . $out
      # Of course there are broken symlinks, why the fuck not
      rm -rf $out/ui/goose2/.{claude,codex}
    '';
  });
  pnpm = pkgs.pnpm_11;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "goose-desktop";
  inherit version;

  src = "${src}/ui";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version;
    inherit pnpm;
    src = "${src}/ui";
    # pnpmWorkspaces = [ "goose-app" ];
    fetcherVersion = 3;
    hash = "sha256-iaiIW+ftIM1M6NkPU/wTRU4C4GnqFKb45jKZkEeeUAU=";
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

  # Skip binary download during build
  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  configurePhase = ''
    runHook preConfigure

    # Set npm_config_nodedir for native module compilation
    export npm_config_nodedir="${electron.headers}"

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    pushd desktop

    # Patch electron-forge to use our electron distribution
    substituteInPlace ../node_modules/@electron-forge/core-utils/dist/electron-version.js \
      --replace-fail "return version" "return '${electron.version}'"
    substituteInPlace \
      ../node_modules/@electron/packager/dist/packager.js \
      --replace-fail "await this.getElectronZipPath(downloadOpts)" "'$(pwd)/electron.zip'"

    # Create electron zip from our electron distribution
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
    pushd electron-dist
    zip -0Xqr ../electron.zip .
    popd
    rm -r electron-dist

    # Build the application
    pnpm run i18n:compile
    # Unrolled the package target, else we need to patchShebangs and patch
    # electron-forge to fix package.json resolution.
    node ../node_modules/@electron-forge/cli/dist/electron-forge.js package

    runHook postBuild

    popd
  '';

  installPhase = ''
    runHook preInstall

    pushd desktop

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

    popd
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
