{ pkgs, pythonPkgs, ... }:
pythonPkgs.buildPythonPackage rec {
  pname = "py-applescript";
  version = "1.0.3";
  format = "setuptools";
  src = pkgs.fetchPypi {
    inherit pname version;
    hash = "sha256-+iLJVfwls9JOA+ZoJbNqchiX7A2bbOGFpNF34tHs+ms=";
  };
}
