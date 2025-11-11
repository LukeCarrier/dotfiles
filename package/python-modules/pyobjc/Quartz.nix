{
  lib,
  pkgs,
  pythonPkgs,
}:
let
  inherit (pkgs) darwin;
  inherit (pythonPkgs)
    buildPythonPackage
    pyobjc-core
    pyobjc-framework-Cocoa
    setuptools
    unittestCheckHook
    ;
in
buildPythonPackage rec {
  pname = "pyobjc-framework-Quartz";
  pyproject = true;

  inherit (pyobjc-core) version src;

  patches = pyobjc-core.patches or [ ];

  sourceRoot = "${src.name}/pyobjc-framework-Quartz";

  build-system = [ setuptools ];

  buildInputs = [
    darwin.libffi
  ];

  nativeBuildInputs = [
    darwin.DarwinTools
  ];

  nativeCheckInputs = [
    unittestCheckHook
  ];

  postPatch = ''
    substituteInPlace pyobjc_setup.py \
      --replace-fail "-buildversion" "-buildVersion" \
      --replace-fail "-productversion" "-productVersion" \
      --replace-fail "/usr/bin/sw_vers" "sw_vers" \
      --replace-fail "/usr/bin/xcrun" "xcrun"
  '';

  dependencies = [
    pyobjc-core
    pyobjc-framework-Cocoa
  ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-I${darwin.libffi.dev}/include"
    "-Wno-error=unused-command-line-argument"
  ];

  pythonImportsCheck = [
    "Quartz"
  ];

  # PyObjCTest.test_cgremoteoperation.TestCGRemoteOperation.testFunctions
  # AssertionError: 1002 != 0
  # PyObjCTest.test_cgsession.TestCGSession.testFunctions
  # AssertionError: None is not an instance of <objective-c class NSDictionary at 0x1f4ea65a8>
  doCheck = false;

  meta = {
    description = "PyObjC wrappers for the Quartz framework on macOS";
    homepage = "https://github.com/ronaldoussoren/pyobjc/tree/main/pyobjc-framework-Quartz";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
