{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  scikit-build,
  cmake,
  ush,
  requests,
  six,
  numpy,
  cffi,
  openfst,
  replaceVars,
  callPackage,
}:

let
  kaldi = callPackage ./kaldi-fork.nix { inherit openfst; };
in
buildPythonPackage rec {
  pname = "kaldi-active-grammar";
  version = "3.1.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "daanzu";
    repo = "kaldi-active-grammar";
    rev = "v${version}";
    sha256 = "0lilk6yjzcy31avy2z36bl9lr60gzwhmyqwqn8akq11qc3mbffsk";
  };

  KALDI_BRANCH = "foo";
  KALDIAG_SETUP_RAW = "1";

  patches = [
    (
      fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b3d51a0365f6695e7dd5cdf3e180604530ed33b4";
        sha256 = "sha256-xEviJY/WPd78G0LY44TO1w6wTPU4l3LL/wCM+8M+YBw=";
      }
      + "/pkgs/development/python-modules/kaldi-active-grammar/0001-stub.patch"
    )
    (
      fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b3d51a0365f6695e7dd5cdf3e180604530ed33b4";
        sha256 = "sha256-xEviJY/WPd78G0LY44TO1w6wTPU4l3LL/wCM+8M+YBw=";
      }
      + "/pkgs/development/python-modules/kaldi-active-grammar/0002-exec-path.patch"
    )
    (replaceVars
      (
        fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "b3d51a0365f6695e7dd5cdf3e180604530ed33b4";
          sha256 = "sha256-xEviJY/WPd78G0LY44TO1w6wTPU4l3LL/wCM+8M+YBw=";
        }
        + "/pkgs/development/python-modules/kaldi-active-grammar/0003-ffi-path.patch"
      )
      {
        kaldiFork = "${kaldi}/lib";
      }
    )
  ];

  preBuild = ''
    cd ..
  '';

  buildInputs = [
    openfst
    kaldi
  ];
  nativeBuildInputs = [
    scikit-build
    cmake
  ];
  propagatedBuildInputs = [
    ush
    requests
    numpy
    cffi
    six
  ];

  doCheck = false;

  meta = with lib; {
    description = "Python Kaldi speech recognition";
    homepage = "https://github.com/daanzu/kaldi-active-grammar";
    license = licenses.agpl3Plus;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
