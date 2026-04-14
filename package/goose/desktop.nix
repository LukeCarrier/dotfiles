{
  goose-cli,
  lib,
  stdenv,
  fetchFromGitHub,
  pkgs,
  ...
}:
let
  inherit (lib) getExe optionalString;
  inherit (pkgs) electron makeDesktopItem;

  fetchPnpmDeps = import ../../lib/fetch-pnpm-deps.nix { inherit pkgs; };
  version = "1.50.1";

  rawSrc = fetchFromGitHub {
    owner = "aaif-goose";
    repo = "goose";
    tag = "v${version}";
    hash = "sha256-n4jslrK5VrhcwzgvLdy2MaL0feQ8+rX+i202UwpAdHE=";
  };
  src = stdenv.mkDerivation (finalAttrs: {
    pname = "goose-desktop";
    inherit version;
    src = rawSrc;
    patches = [ ];
    buildPhase = "true";
    installPhase = ''
      cp -a . $out
      find $out -type l ! -exec test -e {} \; -delete
    '';
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "goose-desktop";
  inherit version src;

  pnpmRoot = "ui";
  pnpmDeps = fetchPnpmDeps {
    pname = finalAttrs.pname;
    inherit version;
    src = "${src}/ui";
    fetcherVersion = 4;
    hash = "sha256-+9KMmyzNmTfe/HMUAoRokU8+orZ0KYlaeZhzHW/S0Y0=";
  };

  nativeBuildInputs = with pkgs; [
    asar
    copyDesktopItems
    makeWrapper
    nodejs_24
    pnpm
    pnpmConfigHook
    zip
  ];

  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  # Electron Forge signs the .app itself after flipping fuses. Nixpkgs' fixup
  # hooks would undo that: `strip` invalidates the signature, and the sigtool
  # re-signer replaces the bundle's signature with a bare binary signature
  # ("code has no resources but signature indicates they must be present").
  # Either way arm64 macOS SIGKILLs the app on launch.
  dontStrip = true;
  darwinDontCodeSign = true;

  buildPhase = ''
    runHook preBuild
    pushd ui

    # @electron/fuses would ad-hoc re-sign the app after flipping fuses, but it
    # does so from the `packageAfterCopy` hook — before packager rewrites
    # Info.plist — so that signature never validates. Sign once in postFixup.
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

    # Create electron zip from our electron distribution. `-y` is essential:
    # without it zip dereferences the frameworks' `Versions/Current` symlinks,
    # which leaves codesign unable to tell app from framework ("bundle format
    # is ambiguous") and no valid signature can be produced.
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
    pushd electron-dist
    zip -0Xqry ../electron.zip .
    popd
    rm -r electron-dist

    # Unrolled the upstream `build` script (npm run generate && npm run build:ts);
    # pnpm resolves tsx/tsc from node_modules/.bin.
    pushd goose-acp-client
    pnpm run generate
    pnpm run build:ts
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

    ${optionalString stdenv.hostPlatform.isDarwin ''
      # The packaged app resolves its backend from
      # Contents/Resources/bin/goose (findGooseBinaryPath); without it startup
      # fails with "Goose binary not found in any of the possible paths".
      for app in $out/share/goose-desktop/*.app; do
        mkdir -p "$app/Contents/Resources/bin"
        cp ${getExe goose-cli} "$app/Contents/Resources/bin/goose"

        # Expose the .app under $out/Applications so Home Manager's macOS app
        # linker (mac-app-util) — which scans each package's Applications/ dir —
        # picks it up into ~/Applications/Home Manager Apps. Glob rather than
        # hard-code the bundle name so a productName change can't silently drop it.
        mkdir -p $out/Applications
        ln -s "$app" "$out/Applications/$(basename "$app")"
      done
    ''}

    ${optionalString stdenv.hostPlatform.isLinux ''
      # Forge's extraResource: ['src/bin'] bundles resources/bin/goose — place
      # the Nix-built binary there so findGooseBinaryPath discovers it naturally
      # in packaged mode (GOOSE_BINARY env var is rejected when isPackaged=true).
      mkdir -p $out/share/goose-desktop/resources/bin
      cp ${getExe goose-cli} $out/share/goose-desktop/resources/bin/goose

      # Our wrapper runs nixpkgs' electron binary directly, passing app.asar
      # as an argument (see makeWrapper below), rather than a renamed,
      # forge-produced executable. Electron derives `process.resourcesPath`
      # from the running binary's own location in this case, so it resolves
      # into electron's own store path instead of our resources dir. Bake in
      # the real path at build time, the same way nixpkgs'
      # youtube-music-desktop-app patches its packaged app.asar.
      asar extract \
        $out/share/goose-desktop/resources/app.asar \
        patched-asar
      sed -i "s#process\.resourcesPath#'$out/share/goose-desktop/resources'#g" \
        patched-asar/.vite/build/main.js
      rm $out/share/goose-desktop/resources/app.asar
      asar pack patched-asar $out/share/goose-desktop/resources/app.asar
      rm -rf patched-asar

      mkdir -p $out/bin
      makeWrapper ${getExe electron} "$out/bin/goose-desktop" \
         --add-flags "$out/share/goose-desktop/resources/app.asar" \
         --set ELECTRON_FORCE_IS_PACKAGED 1

      install -Dm644 src/images/icon.svg "$out/share/icons/hicolor/scalable/apps/goose.svg"
    ''}

    runHook postInstall
  '';

  # arm64 macOS SIGKILLs a bundle whose signature doesn't validate, and flipping
  # fuses invalidates the signature shipped in electron's dist. Sign here rather
  # than in forge: its `packageAfterCopy` hook runs before packager rewrites
  # Info.plist, so its signature never validates. postFixup also runs after
  # patchShebangs, which rewrites scripts inside the bundle.
  postFixup = optionalString stdenv.hostPlatform.isDarwin ''
    for app in $out/share/goose-desktop/*.app; do
      /usr/bin/codesign --force --deep --sign - \
        --preserve-metadata=entitlements,requirements,flags,runtime \
        "$app"
    done
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
