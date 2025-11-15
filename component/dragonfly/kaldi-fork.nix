{
  lib,
  stdenv,
  blas,
  lapack,
  openfst,
  icu,
  pkg-config,
  fetchFromGitHub,
  python,
  openblas,
  zlib,
  gfortran,
}:

let
  old-openfst = openfst.overrideAttrs (prev: {
    version = "kag-unstable-2022-05-06";

    src = fetchFromGitHub {
      owner = "kkm000";
      repo = "openfst";
      rev = "0bca6e76d24647427356dc242b0adbf3b5f1a8d9";
      sha256 = "1802rr14a03zl1wa5a0x1fa412kcvbgprgkadfj5s6s3agnn11rx";
    };
    buildInputs = [ zlib ];
    # PRESERVE patches from the input openfst
    patches = (prev.patches or [ ]);
  });
in

assert blas.implementation == "openblas" && lapack.implementation == "openblas";

stdenv.mkDerivation rec {
  pname = "kaldi";
  version = "kag-v2.1.0";

  src = fetchFromGitHub {
    owner = "daanzu";
    repo = "kaldi-fork-active-grammar";
    rev = version;
    sha256 = "+kT2xJRwDj/ECv/v/J1FpsINWOK8XkP9ZvZ9moFRl70=";
  };

  patches = [
    (
      fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b3d51a0365f6695e7dd5cdf3e180604530ed33b4";
        sha256 = "sha256-xEviJY/WPd78G0LY44TO1w6wTPU4l3LL/wCM+8M+YBw=";
      }
      + "/pkgs/development/python-modules/kaldi-active-grammar/0004-fork-cmake.patch"
    )
    (
      fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b3d51a0365f6695e7dd5cdf3e180604530ed33b4";
        sha256 = "sha256-xEviJY/WPd78G0LY44TO1w6wTPU4l3LL/wCM+8M+YBw=";
      }
      + "/pkgs/development/python-modules/kaldi-active-grammar/0006-fork-configure.patch"
    )
  ];

  enableParallelBuilding = true;

  buildInputs = [
    openblas
    old-openfst
    icu
  ];

  nativeBuildInputs = [
    pkg-config
    python
    gfortran
  ];

  buildFlags = [
    "dragonfly"
    "dragonflybin"
    "bin"
    "fstbin"
    "lmbin"
  ];

  postPatch = ''
    patchShebangs src
    substituteInPlace src/matrix/cblas-wrappers.h \
      --replace stptri_ LAPACK_stptri \
      --replace dtptri_ LAPACK_dtptri \
      --replace sgetrf_ LAPACK_sgetrf \
      --replace dgetrf_ LAPACK_dgetrf \
      --replace sgetri_ LAPACK_sgetri \
      --replace dgetri_ LAPACK_dgetri \
      --replace sgesvd_ LAPACK_sgesvd \
      --replace dgesvd_ LAPACK_dgesvd \
      --replace ssptri_ LAPACK_ssptri \
      --replace dsptri_ LAPACK_dsptri \
      --replace ssptrf_ LAPACK_ssptrf \
      --replace dsptrf_ LAPACK_dsptrf
  '';

  configurePhase = ''
    cd src
    ./configure --shared --fst-root="${old-openfst}" --use-cuda=no --openblas-root="${openblas}" --mathlib=OPENBLAS
  '';

  installPhase = ''
    find . -type f -name "*.o" -print0 | xargs -0 rm -f
    mkdir -p $out/{bin,lib}
    cp lib/* $out/lib/
    patchelf \
      --set-rpath "${lib.makeLibraryPath buildInputs}:$out/lib" \
      $out/lib/*
  '';

  meta = with lib; {
    description = "Speech Recognition Toolkit";
    homepage = "https://kaldi-asr.org";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
