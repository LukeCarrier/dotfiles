{
  pkgs,
  pythonPkgs,
}:
let
  inherit (pkgs) callPackage;
  inherit (pkgs.lib) fix;
in
fix (self: {
  py-applescript = callPackage ./py-applescript.nix {
    pythonPkgs = pythonPkgs // self;
  };

  pyobjc-framework-CoreText = callPackage ./pyobjc/CoreText.nix {
    pythonPkgs = pythonPkgs // self;
  };

  pyobjc-framework-Quartz = callPackage ./pyobjc/Quartz.nix {
    pythonPkgs = pythonPkgs // self;
  };

  pyobjc-framework-ApplicationServices = callPackage ./pyobjc/ApplicationServices.nix {
    pythonPkgs = pythonPkgs // self;
  };
})
