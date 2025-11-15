{ lib, pkgs, ... }:
let
  inherit (pkgs) stdenv;
  dummy = stdenv.mkDerivation {
    pname = "dummy";
    version = "0";

    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
    '';
  };
  pynput = pkgs.python313Packages.pynput.overrideAttrs (oldAttrs: {
    propagatedBuildInputs =
      oldAttrs.propagatedBuildInputs
      ++ (with pkgs.python313Packages; [
        pyobjc-framework-ApplicationServices
        pyobjc-framework-Quartz
      ]);
  });

  # Create a patched version of openfst with the C++ fixes
  openfst-kag-patched = pkgs.openfst.overrideAttrs (old: {
    version = "kag-unstable-2022-05-06-patched";

    src = pkgs.fetchFromGitHub {
      owner = "kkm000";
      repo = "openfst";
      rev = "0bca6e76d24647427356dc242b0adbf3b5f1a8d9";
      sha256 = "1802rr14a03zl1wa5a0x1fa412kcvbgprgkadfj5s6s3agnn11rx";
    };

    buildInputs = old.buildInputs or [ ] ++ [ pkgs.zlib ];

    patches = (old.patches or [ ]) ++ [
      ./openfst-fixes.patch
    ];
  });

  # Use our custom kaldi-active-grammar package that uses patched openfst
  kaldi-active-grammar = pkgs.python313Packages.callPackage ./kaldi-active-grammar.nix {
    openfst = openfst-kag-patched;
  };

  # Patch webrtcvad to use importlib.metadata instead of deprecated pkg_resources
  webrtcvad = pkgs.python313Packages.webrtcvad.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./webrtcvad-no-pkg-resources.patch
    ];
  });

  dragonfly =
    (pkgs.python313Packages.dragonfly.override {
      inherit pynput kaldi-active-grammar;
      xdotool = if stdenv.hostPlatform.isLinux then pkgs.xdotool else dummy;
      wmctrl = if stdenv.hostPlatform.isLinux then pkgs.wmctrl else dummy;
      xorg.xprop = if stdenv.hostPlatform.isLinux then pkgs.xorg.xprop else dummy;
    }).overrideAttrs
      (oldAttrs: {
        propagatedBuildInputs =
          oldAttrs.propagatedBuildInputs
          ++ (
            if stdenv.hostPlatform.isDarwin then
              with pkgs.python313Packages;
              [
                py-applescript
                pyobjc-core
                pyobjc-framework-ApplicationServices
                pyobjc-framework-Quartz
                pyobjc-framework-CoreText
              ]
            else
              [ ]
          );

        # Patch to allow newer py-applescript version and remove pyobjc meta-package
        postPatch = (oldAttrs.postPatch or "") + ''
          sed -i.bak setup.py \
            -e 's/py-applescript == 1.0.0/py-applescript >= 1.0.0/g' \
            -e '/pyobjc >= 5.2;platform_system/d'
        '';

        # Disable runtime dependency check since we're providing the actual pyobjc frameworks
        pythonRuntimeDepsCheck = false;
      });

  # Package for make-it-work.py grammar script
  dragonfly-grammar = pkgs.python313Packages.buildPythonApplication {
    pname = "dragonfly-grammar";
    version = "0.1.0";

    src = ./grammar;

    format = "other";

    propagatedBuildInputs = [
      dragonfly
      kaldi-active-grammar
      pkgs.python313Packages.sounddevice
      webrtcvad
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p "$out/bin"

      cp make-it-work.py "$out/bin/dragonfly-grammar"
      chmod +x "$out/bin/dragonfly-grammar"
    '';

    meta = with lib; {
      description = "Dragonfly grammar for voice control";
      platforms = platforms.unix;
    };
  };
in
{
  home.packages = [
    dragonfly-grammar
  ];
}
