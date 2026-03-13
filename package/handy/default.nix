{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  bun,
  cacert,
  jq,
  pkg-config,
  wrapGAppsHook4,
  cmake,
  llvmPackages,
  shaderc,
  webkitgtk_4_1,
  gtk3,
  glib,
  glib-networking,
  libsoup_3,
  alsa-lib,
  onnxruntime,
  libayatana-appindicator,
  libevdev,
  libx11,
  libxtst,
  gtk-layer-shell,
  openssl,
  vulkan-loader,
  vulkan-headers,
  gst_all_1,
}:

let
  version = "0.7.10";
  src = fetchFromGitHub {
    owner = "cjpais";
    repo = "Handy";
    rev = "01b8b05bdc7b0f00c064a4b2b4a199a6aa66bfef";
    hash = "sha256-ef0HPxwpr3emVydLvJhfrHBVkh9QqXxUY5lq8IzYGok=";
  };

  bunDeps = stdenv.mkDerivation {
    pname = "handy-bun-deps";
    inherit version src;

    nativeBuildInputs = [
      bun
      cacert
    ];

    dontFixup = true;

    buildPhase = ''
      export HOME=$TMPDIR
      bun install --frozen-lockfile --no-progress
    '';

    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    # Fixed hash for the actual bun.lock file
    outputHash = "sha256-x8SP6k7eZwlPhOuQ876aVI+hFxRUiYRWrdCDdQh7jY4=";
  };
in
rustPlatform.buildRustPackage {
  pname = "handy";
  inherit version src;

  cargoRoot = "src-tauri";

  cargoLock = {
    lockFile = "${src}/src-tauri/Cargo.lock";
    outputHashes = {
      "rdev-0.5.0-2" = "sha256-0F7EaPF8Oa1nnSCAjzEAkitWVpMldL3nCp3c5DVFMe0=";
      "rodio-0.20.1" = "sha256-wq72awTvN4fXZ9qZc5KLYS9oMxtNDZ4YGxfqz8msofs=";
      "tauri-nspanel-2.1.0" = "sha256-gotQQ1DOhavdXU8lTEux0vdY880LLetk7VLvSm6/8TI=";
      "tauri-runtime-2.10.0" = "sha256-s1IBM9hOY+HRdl/E5r7BsRTE7aLaFCCMK/DdS+bvZRc=";
      "vad-rs-0.1.5" = "sha256-Q9Dxq31npyUPY9wwi6OxqSJrEvFvG8/n0dbyT7XNcyI=";
    };
  };

  postPatch = ''
    ${jq}/bin/jq 'del(.build.beforeBuildCommand) | .bundle.createUpdaterArtifacts = false' \
      src-tauri/tauri.conf.json > $TMPDIR/tauri.conf.json
    cp $TMPDIR/tauri.conf.json src-tauri/tauri.conf.json

    # Point libappindicator-sys to the Nix store path
    substituteInPlace \
      $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
      --replace-fail \
        "libayatana-appindicator3.so.1" \
        "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"

    # Disable cbindgen in ferrous-opencc (calls cargo metadata which fails in sandbox)
    substituteInPlace $cargoDepsCopy/ferrous-opencc-0.2.3/build.rs \
      --replace-fail '.expect("Unable to generate bindings")' '.ok();'
    substituteInPlace $cargoDepsCopy/ferrous-opencc-0.2.3/build.rs \
      --replace-fail '.write_to_file("opencc.h");' '// skipped'
  '';

  preBuild = ''
    cp -r ${bunDeps}/node_modules node_modules
    chmod -R +w node_modules
    substituteInPlace node_modules/.bin/{tsc,vite} \
      --replace-fail "/usr/bin/env node" "${lib.getExe bun}"
    export HOME=$TMPDIR
    bun run build
  '';

  # Tests require runtime resources (audio devices, model files, GPU/Vulkan)
  # not available in the Nix build sandbox
  doCheck = false;

  # The tauri hook's installPhase expects target/ in cwd, but our
  # cargoRoot puts it under src-tauri/. Override to extract the DEB.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cd src-tauri
    mv target/${stdenv.hostPlatform.rust.rustcTarget}/release/bundle/deb/*/data/usr/* $out/
    runHook postInstall
  '';

  nativeBuildInputs = with pkgs; [
    cargo-tauri.hook
    pkg-config
    wrapGAppsHook4
    bun
    jq
    cmake
    llvmPackages.libclang
    shaderc
  ];

  buildInputs = with pkgs; [
    webkitgtk_4_1
    gtk3
    glib
    glib-networking
    libsoup_3
    alsa-lib
    onnxruntime
    libayatana-appindicator
    libevdev
    libx11
    libxtst
    gtk-layer-shell
    openssl
    vulkan-loader
    vulkan-headers
    shaderc

    # Required for WebKitGTK audio/video
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];

  env = {
    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${llvmPackages.libclang.lib}/lib/clang/${lib.getVersion llvmPackages.libclang}/include -isystem ${pkgs.glibc.dev}/include";
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
    OPENSSL_NO_VENDOR = "1";

    # Tell Gstreamer where to find plugins
    GST_PLUGIN_SYSTEM_PATH_1_0 = "${lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
      with gst_all_1;
      [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
      ]
    )}";
  };

  preFixup = ''
    gappsWrapperArgs+=(
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          pkgs.vulkan-loader
          pkgs.onnxruntime
        ]
      }"
    )
  '';

  meta = {
    description = "A free, open source, and extensible speech-to-text application that works completely offline";
    homepage = "https://github.com/cjpais/Handy";
    license = lib.licenses.mit;
    mainProgram = "handy";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
