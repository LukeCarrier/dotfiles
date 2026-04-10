{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  rustPlatform,
  cmake,
  dbus,
  libxcb,
  pkg-config,
  protobuf,
  openssl,
  cacert,
  writableTmpDirAsHomeHook,
  versionCheckHook,
  nix-update-script,
  llvmPackages,
  makeWrapper,
  librusty_v8 ? callPackage ./librusty_v8.nix {
    inherit (callPackage ./fetchers.nix { }) fetchLibrustyV8;
  },

  # Extension(s) Dependencies
  python3,
  bash,
  # X11
  xdotool,
  wmctrl,
  xclip,
  xwininfo,
  # Wayland
  wtype,
  wl-clipboard,
}:

let
  # NOTE: When updating, also update the hash in goose-cli/librusty_v8.nix
  gpt4o-tokenizer = fetchurl {
    url = "https://huggingface.co/Xenova/gpt-4o/resolve/31376962e96831b948abe05d420160d0793a65a4/tokenizer.json";
    hash = "sha256-Q6OtRhimqTj4wmFBVOoQwxrVOmLVaDrgsOYTNXXO8H4=";
    meta.license = lib.licenses.mit;
  };

  claude-tokenizer = fetchurl {
    url = "https://huggingface.co/Xenova/claude-tokenizer/resolve/cae688821ea05490de49a6d3faa36468a4672fad/tokenizer.json";
    hash = "sha256-wkFzffJLTn98mvT9zuKaDKkD3LKIqLdTvDRqMJKRF2c=";
    meta.license = lib.licenses.mit;
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "goose-cli";
  version = "1.28.0";

  src = fetchFromGitHub {
    owner = "block";
    repo = "goose";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/1TtsnNiLoTkvyeFR282qSpo+Jt3pvFxduJ7lyzsTXI=";
  };

  cargoHash = "sha256-bhnbSjGqyWbQd5PjZ116JH91vjVy6R/+iBlNKL6debg=";

  cargoBuildFlags = [
    "--bin"
    "goose"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    protobuf
    rustPlatform.bindgenHook
    makeWrapper
  ];

  buildInputs = [
    dbus
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ libxcb ];

  env = {
    LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";
    RUSTY_V8_ARCHIVE = librusty_v8;
  };

  preBuild = ''
    mkdir -p tokenizer_files/Xenova--gpt-4o tokenizer_files/Xenova--claude-tokenizer
    ln -s ${gpt4o-tokenizer} tokenizer_files/Xenova--gpt-4o/tokenizer.json
    ln -s ${claude-tokenizer} tokenizer_files/Xenova--claude-tokenizer/tokenizer.json
  '';

  postFixup = ''
    wrapProgram $out/bin/goose \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            bash
            python3
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            # X11
            xdotool
            wmctrl
            xclip
            xwininfo
            # Wayland
            wtype
            wl-clipboard
          ]
        )
      }
  '';

  nativeCheckInputs = [
    writableTmpDirAsHomeHook
    cacert
  ];

  __darwinAllowLocalNetworking = true;

  # Tests are flaky and slow, so we disable them by default but can be enabled with:
  #   nix build .#goose-cli --arg doCheck true
  doCheck = false;

  # The test suite contains several hardcoded sleeps which can be flaky on slower systems
  # or under high load, so we disable these specific tests.
  checkPhase = ''
    runHook preCheck

    # Because of how rustPlatform.buildRustPackage works, the workdir is set to the workspace root
    # which means we need to run cargo test from there, but we only want to run the tests
    # from the CLI crate
    cargo test -p goose-cli --release -- --test-threads 1 \
    ${lib.optionalString stdenv.hostPlatform.isDarwin "--skip=test_get_node_version_with_bad_ruby_path"} \
    ${lib.optionalString stdenv.hostPlatform.isDarwin "--skip=browser::tests::test_browser_action_click"} \
    ${lib.optionalString stdenv.hostPlatform.isDarwin "--skip=browser::tests::test_browser_action_screenshot"} \
    ${lib.optionalString stdenv.hostPlatform.isDarwin "--skip=browser::tests::test_browser_action_get_html"} \
    ${lib.optionalString stdenv.hostPlatform.isDarwin "--skip=browser::tests::test_browser_action_get_text"} \
    --skip=context_mgmt::auto_compact::tests::test_auto_compact_respects_config \
    --skip=scheduler::tests::test_scheduled_session_has_schedule_id
  '' + lib.optionalString (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64) ''
    # Broken on aarch64-linux: request capture races across session_id_propagation_test cases
    cargo test -p goose-cli --release -- --test-threads 1 \
    --skip=test_session_id_matches_across_calls \
    --skip=test_session_id_propagation_to_llm
  '' + lib.optionalString stdenv.hostPlatform.isDarwin ''
    cargo test -p goose-cli --release -- --test-threads 1 \
    --skip=logging::tests::test_log_file_name_no_session \
    --skip=recipes::extract_from_cli::tests::test_extract_recipe_info_from_cli_basic \
    --skip=recipes::extract_from_cli::tests::test_extract_recipe_info_from_cli_with_screenshots \
    --skip=recipes::extract_from_cli::tests::test_extract_recipe_info_from_cli_overwrite \
    --skip=test_session_id_propagation_to_llm
  '' + ''
    runHook postCheck
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "The open source agent framework for automating the web and your computer";
    homepage = "https://github.com/block/goose";
    license = lib.licenses.asl20;
    mainProgram = "goose";
    maintainers = with lib.maintainers; [
      cloudripper
      thardin
      brittonr
      miniharinn
      caniko
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
