{
  lib,
  stdenv,
  fetchFromGitHub,
  makeRustPlatform,
  rust-bin,
  rustPlatform,
  pkg-config,
  makeWrapper,
  darwin,
}:
let
  rustToolchain = rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
  openwarpRustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  version = "0-unstable-2026-05-01";
  rev = "b5dd43c4c5f21d60fb9be10378268c22cc6d7095";
  darwinArch =
    if stdenv.hostPlatform.system == "aarch64-darwin" then
      "arm64"
    else
      "x86_64";
in
openwarpRustPlatform.buildRustPackage {
  pname = "openwarp";
  inherit version;

  src = fetchFromGitHub {
    owner = "zerx-lab";
    repo = "warp";
    inherit rev;
    hash = "sha256-9dV1WHoac68KLVdOl/Yl2DQysRoBA937hNcU8VYqGdo=";
  };

  cargoHash = lib.fakeHash;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin (
    with darwin.apple_sdk.frameworks;
    [
      AppKit
      AVFoundation
      Carbon
      Cocoa
      CoreFoundation
      CoreGraphics
      Foundation
      Metal
      MetalKit
      QuartzCore
      Security
      ServiceManagement
      SystemConfiguration
      UniformTypeIdentifiers
      UserNotifications
    ]
  );

  postPatch = ''
    substituteInPlace app/DockTilePlugin/Makefile \
      --replace-fail "-arch arm64 -arch x86_64" "-arch ${darwinArch}"
  '';

  MACOSX_DEPLOYMENT_TARGET = "10.14";
  GIT_CONFIG_GLOBAL = "/dev/null";
  GIT_RELEASE_TAG = "v${version}";

  cargoBuildFlags = [
    "--package"
    "warp"
    "--bin"
    "warp-oss"
    "--features"
    "release_bundle,gui,nld_improvements"
  ];

  doCheck = false;

  installPhase = ''
    runHook preInstall

    appDir="$out/Applications/OpenWarp.app"
    contentsDir="$appDir/Contents"
    resourcesDir="$contentsDir/Resources"

    install -Dm755 target/release/warp-oss "$contentsDir/MacOS/warp-oss"
    install -Dm644 channels/oss/icon/no-padding/512x512.png "$resourcesDir/icon.png"

    mkdir -p "$contentsDir/PlugIns"
    cp -R target/release/WarpDockTilePlugin.docktileplugin "$contentsDir/PlugIns/"

    cat > "$contentsDir/Info.plist" <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleDevelopmentRegion</key>
      <string>English</string>
      <key>CFBundleDisplayName</key>
      <string>OpenWarp</string>
      <key>CFBundleExecutable</key>
      <string>warp-oss</string>
      <key>CFBundleIdentifier</key>
      <string>dev.openwarp.OpenWarp</string>
      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
      <key>CFBundleName</key>
      <string>OpenWarp</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleShortVersionString</key>
      <string>${version}</string>
      <key>CFBundleVersion</key>
      <string>${version}</string>
      <key>LSApplicationCategoryType</key>
      <string>public.app-category.developer-tools</string>
      <key>NSDockTilePlugIn</key>
      <string>WarpDockTilePlugin.docktileplugin</string>
      <key>NSHighResolutionCapable</key>
      <true/>
      <key>LSBackgroundOnly</key>
      <false/>
      <key>CFBundleURLTypes</key>
      <array>
        <dict>
          <key>CFBundleURLName</key>
          <string>OpenWarp</string>
          <key>CFBundleURLSchemes</key>
          <array>
            <string>openwarp</string>
          </array>
        </dict>
      </array>
    </dict>
    </plist>
EOF

    mkdir -p "$resourcesDir/bin"
    makeWrapper "$contentsDir/MacOS/warp-oss" "$out/bin/openwarp"
    makeWrapper "$contentsDir/MacOS/warp-oss" "$resourcesDir/bin/warp-oss"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Community fork of Warp terminal with local OpenAI-compatible AI providers";
    homepage = "https://github.com/zerx-lab/warp/tree/openWarp";
    license = licenses.agpl3Only;
    mainProgram = "openwarp";
    platforms = platforms.darwin;
  };
}
