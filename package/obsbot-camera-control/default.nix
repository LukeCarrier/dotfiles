{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  cmake,
  patchelf,
  pkg-config,
  autoPatchelfHook,
  copyDesktopItems,
  pipewire,
  libglvnd,
  qt6,
  makeDesktopItem,
}:

let
  version = "1.3.0";
  commonBuildInputs = [ libglvnd pipewire ] ++ [ qt6.qtbase qt6.qtmultimedia ];
  commonNativeBuildInputs = [
    autoPatchelfHook
    cmake
    makeWrapper
    patchelf
    pkg-config
  ];
  src = fetchFromGitHub {
    owner = "aaronsb";
    repo = "obsbot-camera-control";
    rev = "v${version}";
    hash = "sha256-Q9Y+TpD0W0CdFYrDNfi5CvF9crViCiSzc+nJUBh6MGI=";
  };

  obsbot-sdk = stdenv.mkDerivation rec {
    pname = "obsbot-sdk";
    version = "1.3.0";

    inherit src;

    # Required for autoPatchelfHook to resolve libstdc++.so.6 and libgcc_s.so.1
    buildInputs = [ stdenv.cc.cc ];

    nativeBuildInputs = [ autoPatchelfHook ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r sdk/v*/lib $out/lib
      cp -r sdk/v*/include $out/include
      runHook postInstall
    '';

    meta = with lib; {
      description = "OBSBOT Camera SDK - headers and libraries";
      license = licenses.unfree;
      maintainers = [ ];
    };
  };

  build = stdenv.mkDerivation rec {
    pname = "obsbot-camera-control";
    version = "1.3.0";

    inherit src;

    # Required for autoPatchelfHook to resolve libstdc++.so.6 and libgcc_s.so.1
    buildInputs = [ stdenv.cc.cc obsbot-sdk ] ++ commonBuildInputs;
    nativeBuildInputs = commonNativeBuildInputs ++ [ qt6.wrapQtAppsHook ];

    buildPhase = ''
      cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$out
      make
    '';

    installPhase = ''
      runHook preInstall
      pushd ..

      for bin in bin/*; do
        patchelf --remove-rpath "$bin"
      done

      mkdir -p $out/bin
      cp bin/obsbot-cli $out/bin/
      cp bin/obsbot-gui $out/bin/

      popd
      runHook postInstall
    '';
  };
in
rec {
  inherit obsbot-sdk;
  obsbot-camera-control-cli = stdenv.mkDerivation rec {
    pname = "obsbot-camera-control-cli";
    version = "1.3.0";

    inherit src;
    nativeBuildInputs = [ copyDesktopItems qt6.wrapQtAppsHook ];
    buildInputs = [ build qt6.qtbase ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp ${build}/bin/obsbot-cli $out/bin/
      runHook postInstall
    '';

    meta = with lib; {
      description = "CLI application for OBSBOT camera control";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
      mainProgram = "obsbot-cli";
    };
  };

  obsbot-camera-control-gui = stdenv.mkDerivation rec {
    pname = "obsbot-camera-control-gui";
    version = "1.3.0";

    inherit src;

    nativeBuildInputs = [ copyDesktopItems qt6.wrapQtAppsHook ];
    buildInputs = [ build qt6.qtbase ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp ${build}/bin/obsbot-gui $out/bin/
      install -D resources/icons/camera.svg $out/share/icons/hicolor/scalable/apps/obsbot-camera-control.svg
      install -D -t $out/share/doc/obsbot-camera-control-gui README.md LICENSE

      runHook postInstall
    '';

    qtWrapperArgs = [
      "--prefix" "LD_LIBRARY_PATH" ":" (
        lib.makeLibraryPath [ pipewire ]
      )
    ];

    desktopItems = [
      (makeDesktopItem {
        name = "obsbot-camera-control";
        desktopName = "OBSBOT Camera Control";
        exec = "obsbot-gui";
        terminal = false;
        icon = "obsbot-camera-control";
        startupWMClass = "obsbot-camera-control";
        comment = "";
        categories = [ "AudioVideo" "Video" ];
      })
    ];

    meta = with lib; {
      description = "Native Linux GUI control app for OBSBOT cameras";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
      mainProgram = "obsbot-gui";
    };
  };
}
