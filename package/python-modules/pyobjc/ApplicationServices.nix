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
    pyobjc-framework-CoreText
    pyobjc-framework-Quartz
    setuptools
    unittestCheckHook
    ;
in
buildPythonPackage rec {
  pname = "pyobjc-framework-ApplicationServices";
  pyproject = true;

  inherit (pyobjc-core) version src;

  patches = pyobjc-core.patches or [ ];

  sourceRoot = "${src.name}/pyobjc-framework-ApplicationServices";

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
    pyobjc-framework-CoreText
    pyobjc-framework-Quartz
  ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-I${darwin.libffi.dev}/include"
    "-Wno-error=unused-command-line-argument"
  ];

  pythonImportsCheck = [
    "ApplicationServices"
  ];

  meta = {
    description = "PyObjC wrappers for the ApplicationServices framework on macOS";
    homepage = "https://github.com/ronaldoussoren/pyobjc/tree/main/pyobjc-framework-ApplicationServices";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
