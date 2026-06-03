{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  clang,
  makeBinaryWrapper,
  mold,
  wrapGAppsHook4,
  gtk4,
  gtk4-layer-shell,
  libinput,
  wayland,
  wayland-protocols,
  dbus,
  libappindicator-gtk3,
  libxkbcommon,
  alsa-lib,
  libpulseaudio,
  pipewire,
  libjack2,
  copyDesktopItems,
  makeDesktopItem,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "hibiki";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "linuxmobile";
    repo = "hibiki";
    rev = "v${finalAttrs.version}";
    hash = "sha256-LxkzCEaAqyOhaFfrd+aBc86Dp9UDkpQYCOyylEuF+lw=";
  };

  cargoHash = "sha256-yN2u+3pXhP6Rq3Ha/fopC1iLevQVl6D6FL2WxjU1Gp4=";

  nativeBuildInputs = [
    mold
    clang
    copyDesktopItems
    pkg-config
    makeBinaryWrapper
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
    libinput
    wayland
    wayland-protocols
    dbus
    libappindicator-gtk3
    libxkbcommon
    alsa-lib
    libpulseaudio
    pipewire
    libjack2
  ];

  postInstall = ''
    install -Dm444 ${./hibiki.svg} $out/share/icons/hicolor/scalable/apps/hibiki.svg
    mkdir -p $out/share/hibiki
    cp -r src/assets/sounds $out/share/hibiki/sounds
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath (finalAttrs.buildInputs ++ [ pipewire libjack2 alsa-lib libpulseaudio ])}"
      --set HIBIKI_SOUNDS_DIR "$out/share/hibiki/sounds"
    )
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "hibiki";
      desktopName = "Hibiki";
      exec = "hibiki";
      terminal = false;
      icon = "hibiki";
      startupWMClass = "hibiki";
      comment = "Elevating the tactile dialogue. A high-fidelity visual and auditory companion that gives your keystrokes a modern resonance.";
      categories = [ "AudioVideo" "Video" ];
    })
  ];

  meta = with lib; {
    description = "Elevating the tactile dialogue. A high-fidelity visual and auditory companion that gives your keystrokes a modern resonance.";
    homepage = "https://github.com/linuxmobile/hibiki";
    license = licenses.mit;
    mainProgram = "hibiki";
    platforms = platforms.unix;
  };
})
