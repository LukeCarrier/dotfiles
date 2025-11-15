{
  pkgs,
}:
pkgs.python311Packages.buildPythonPackage rec {
  pname = "spec-kit";
  version = "0.0.79";

  src = pkgs.fetchFromGitHub {
    owner = "github";
    repo = "spec-kit";
    rev = "v${version}";
    hash = "sha256-A5WQ6/YeEfYrGRxO/V7grKB3O2wv4WIXBvNBAYxAx4Y=";
  };

  format = "pyproject";

  nativeBuildInputs = with pkgs; [
    git
    python311Packages.hatchling
  ];

  propagatedBuildInputs = with pkgs.python311Packages; [
    httpx
    platformdirs
    readchar
    rich
    truststore
    typer
  ];

  meta = with pkgs.lib; {
    description = "Toolkit for Spec-Driven Development";
    homepage = "https://github.com/github/spec-kit";
    license = licenses.mit;
  };
}
