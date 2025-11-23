{ pkgs }:
{
  python313Packages = import ./python-modules {
    inherit pkgs;
    pythonPkgs = pkgs.python313Packages;
  };
}
