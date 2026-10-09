# Patches disko's lib/tests.nix (install-test harness) without import-from-derivation
# during normal evaluation. The unpatched diskoLib is used for everything except
# testLib, which is a lazy attr forced only when system.build.installTest is built.
{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  makeTest = import "${modulesPath}/../tests/make-test-python.nix";
  eval-config = import "${modulesPath}/../lib/eval-config.nix";
  qemu-common = import "${modulesPath}/../lib/qemu-common.nix";

  patchedDisko = pkgs.applyPatches {
    name = "disko-install-test-${
      builtins.substring 0 8 (builtins.hashFile "sha256" ../../system/disko-install-test.patch)
    }";
    src = inputs.disko;
    patches = [ ../../system/disko-install-test.patch ];
  };

  patchedTestLib = import "${patchedDisko}/lib/tests.nix" {
    inherit
      lib
      makeTest
      eval-config
      ;
    qemu-common-lib =
      pkgs: qemu-common {
        inherit lib;
        inherit (pkgs) stdenv;
      };
  };
in
{
  _module.args.diskoLib = lib.mkForce (
    (import "${inputs.disko}/lib" {
      inherit
        lib
        makeTest
        eval-config
        qemu-common
        ;
      rootMountPoint = config.disko.rootMountPoint;
    })
    // { testLib = patchedTestLib; }
  );
}
