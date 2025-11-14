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
  # Create a patched version of the specific openfst used by kaldi-active-grammar
  # This is the "old-openfst" from fork.nix with the kag-unstable version
  openfst-kag-patched = pkgs.openfst.overrideAttrs (old: {
    version = "kag-unstable-2022-05-06";

    src = pkgs.fetchFromGitHub {
      owner = "kkm000";
      repo = "openfst";
      rev = "0bca6e76d24647427356dc242b0adbf3b5f1a8d9";
      sha256 = "1802rr14a03zl1wa5a0x1fa412kcvbgprgkadfj5s6s3agnn11rx";
    };

    buildInputs = old.buildInputs or [ ] ++ [ pkgs.zlib ];

    patches = (old.patches or [ ]) ++ [ ../../package/kaldi/openfst-bi-table-fix.patch ];
  });

  # Override kaldi-active-grammar to use patched fork
  kaldi-active-grammar = pkgs.python313Packages.kaldi-active-grammar.overridePythonAttrs (old: {
    buildInputs = map (
      input:
      if (input.pname or "") == "kaldi" then
        (input.overrideAttrs (kaldiOld: {
          buildInputs = map (
            kaldiInput: if (kaldiInput.pname or "") == "openfst" then openfst-kag-patched else kaldiInput
          ) (kaldiOld.buildInputs or [ ]);
        }))
      else
        input
    ) (old.buildInputs or [ ]);

    meta = old.meta // {
      platforms = lib.platforms.unix;
    };
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

  # Create a patched version of openfst by copying the original and applying our fix
  # This is a regular derivation (not a FOD) so we can use postPatch
  openfst-patched = stdenv.mkDerivation {
    name = "openfst-patched";
    src = pkgs.kaldi.passthru.sources.openfst;

    dontBuild = true;
    dontConfigure = true;

    postPatch = ''
      # Fix bi-table.h copy constructor bug where it references table.s_ instead of table.selector_
      sed -i 's/table\.s_/table.selector_/g' src/include/fst/bi-table.h
    '';

    installPhase = ''
      cp -r . $out
    '';
  };

  # Override kaldi to use the patched openfst source
  kaldi = pkgs.kaldi.overrideAttrs (oldAttrs: {
    # Update cmakeFlags to use the patched openfst
    cmakeFlags = builtins.map (
      flag:
      if lib.hasPrefix "-DFETCHCONTENT_SOURCE_DIR_OPENFST" flag then
        "-DFETCHCONTENT_SOURCE_DIR_OPENFST:PATH=${openfst-patched}"
      else
        flag
    ) oldAttrs.cmakeFlags;
  });

  # Package for make-it-work.py grammar script
  dragonfly-grammar = pkgs.python313Packages.buildPythonApplication {
    pname = "dragonfly-grammar";
    version = "0.1.0";

    src = ./grammar;

    format = "other";

    propagatedBuildInputs = [
      dragonfly
      kaldi
      kaldi-active-grammar
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
