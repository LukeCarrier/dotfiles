{
  goose-server,
  lib,
  stdenv,
  fetchFromGitHub,
  pkgs,
  ...
}:
let
  pnpm2nix = pkgs.callPackage ./pnpm2nix.nix {};
  inherit (lib) getExe makeBinPath;
  inherit (pkgs) electron;

  version = "1.32.0";
  src = fetchFromGitHub {
    owner = "aaif-goose";
    repo = "goose";
    tag = "v${version}";
    sha256 = "sha256-n0u98JY10klMqvPALNxifnHQJWqaTBfKEIZrWfZAVSY=";
  };
  uiSrc = "${src}/ui";
  desktopSrc = "${uiSrc}/desktop";
in
pnpm2nix.mkPnpmPackage {
  pname = "goose-desktop";
  inherit version;
  src = uiSrc;

  extraNativeBuildInputs = with pkgs; [
    makeWrapper
    zip
  ];

  workspace = uiSrc;
  components = [ "desktop" ];
  pnpmLockYaml = "${uiSrc}/pnpm-lock.yaml";

  buildEnv.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  scriptFull = ''
    cd desktop

    export npm_config_nodedir="${electron.headers}"

    substituteInPlace ../node_modules/@electron-forge/core-utils/dist/electron-version.js \
      --replace-fail "return version" "return '${electron.version}'"
    substituteInPlace \
      ../node_modules/@electron/packager/dist/packager.js \
      --replace-fail "await this.getElectronZipPath(downloadOpts)" "'$(pwd)/electron.zip'"

    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
    pushd electron-dist
    zip -0Xqr ../electron.zip .
    popd
    rm -r electron-dist

    pnpm run i18n:compile
    # Unrolled the package target, else we need to patchShebangs and patch
    # electron-forge to fix package.json resolution.
    node ../node_modules/@electron-forge/cli/dist/electron-forge.js package
    mkdir out/share
    mv out/Goose-* out/share/goose-desktop

    makeWrapper ${getExe electron} "out/bin/goose-desktop" \
      --add-flags "$out/share/goose-desktop/resources/app.asar" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
      --set-default GOOSED_BINARY ${getExe goose-server}
  '';

  distDirIsOut = true;
  distDir = "out";

  nodejs = pkgs.nodejs;
  pnpm = pkgs.pnpm;
}
