{
  lib,
  alsa-lib,
  atk,
  buzz-acp,
  buzz-agent,
  buzz-cli,
  buzz-dev-mcp,
  cairo,
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  fetchPnpmDeps,
  fetchurl,
  gdk-pixbuf,
  git-credential-nostr,
  glib,
  gtk3,
  libsoup_3,
  makeDesktopItem,
  makeWrapper,
  nodejs,
  opus,
  pango,
  pkg-config,
  pnpmConfigHook,
  pnpm_11,
  runCommand,
  rustPlatform,
  stdenv,
  webkitgtk_4_1,
}:
let
  inherit (stdenv.hostPlatform) config;
  targetTriple = config;
  version = "0.4.23";

  sherpaOnnxArchive = fetchurl {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.4/sherpa-onnx-v1.13.4-linux-x64-static-lib.tar.bz2";
    hash = "sha256-mLDjGZZCb254JE284ZVVSPLGTo8BxL51uFr3zaoujVw=";
  };
  sherpaOnnxDir = runCommand "sherpa-onnx-archive-dir" {} ''
    mkdir -p $out
    ln -s ${sherpaOnnxArchive} $out/sherpa-onnx-v1.13.4-linux-x64-static-lib.tar.bz2
  '';
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz-desktop";
  inherit version;

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "v${finalAttrs.version}";
    hash = "sha256-gxjoDvfKj0UhHZfOVSO0UZBx31oZJVXThgYGPRtjiPU=";
  };

  cargoRoot = "desktop/src-tauri";
  cargoHash = "sha256-a5oKXIG16SH1NUY8Qokicdmkh7yY0AFwgBfoGsBDCvk=";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  env.SHERPA_ONNX_ARCHIVE_DIR = sherpaOnnxDir;

  pnpmRoot = "desktop";
  pnpmDeps = fetchPnpmDeps {
    pname = finalAttrs.pname;
    inherit version;
    src = finalAttrs.src;
    fetcherVersion = 4;
    hash = "sha256-pQwE16OPgxr+zWhBcky4r8cYkeyUDQurIuJ0E9O84Qo=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    pnpm_11
    nodejs
    pnpmConfigHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    libsoup_3
    opus
    pango
    webkitgtk_4_1
  ];

  preBuild = ''
    # Place companion binaries where Tauri's build.rs can find them.
    # Tauri appends the target triple (e.g. -x86_64-unknown-linux-gnu)
    # to each externalBin entry at build time.
    mkdir -p desktop/src-tauri/binaries
    cp ${buzz-cli}/bin/buzz desktop/src-tauri/binaries/buzz-${targetTriple}
    cp ${buzz-acp}/bin/buzz-acp desktop/src-tauri/binaries/buzz-acp-${targetTriple}
    cp ${buzz-agent}/bin/buzz-agent desktop/src-tauri/binaries/buzz-agent-${targetTriple}
    cp ${buzz-dev-mcp}/bin/buzz-dev-mcp desktop/src-tauri/binaries/buzz-dev-mcp-${targetTriple}
    cp ${git-credential-nostr}/bin/git-credential-nostr desktop/src-tauri/binaries/git-credential-nostr-${targetTriple}

    # Build the frontend: pnpm install (via pnpmConfigHook) + pnpm build
    pushd desktop
    pnpm build
    popd
  '';

  doCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/buzz-desktop $out/share/icons/hicolor/scalable/apps
    cp target/${targetTriple}/release/buzz-desktop $out/share/buzz-desktop/
    makeWrapper $out/share/buzz-desktop/buzz-desktop $out/bin/buzz-desktop

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Buzz";
      desktopName = "Buzz";
      exec = "buzz-desktop %U";
      terminal = false;
      icon = "buzz";
      startupWMClass = "buzz";
      categories = [ "Network" "Development" ];
    })
  ];

  meta = with lib; {
    description = "A workspace where humans and agents build together, on a relay you own";
    homepage = "https://buzz.xyz";
    license = licenses.asl20;
    mainProgram = "buzz-desktop";
    platforms = platforms.linux;
  };
})
