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
  # XXX: move to packages
  pynput = pkgs.python313Packages.pynput.overrideAttrs (oldAttrs: {
    propagatedBuildInputs =
      oldAttrs.propagatedBuildInputs
      ++ (with pkgs.python313Packages; [
        pyobjc-framework-ApplicationServices
        pyobjc-framework-Quartz
      ]);
  });
  dragonfly =
    (pkgs.python313Packages.dragonfly.override {
      inherit pynput;
      # Unavailable outside of Linux
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
in
{
  home.packages = [
    dragonfly
    kaldi
  ];
}
