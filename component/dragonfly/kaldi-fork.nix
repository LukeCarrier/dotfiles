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
  darwin,
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
        sha256 = "sha256-4vhDuZ7OZaZmKKrnDpxLZZpGIJvAeMtK6FKLJYUtAdw=";
      }
      + "/pkgs/development/python-modules/kaldi-active-grammar/0004-fork-cmake.patch"
    )
    (
      fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b3d51a0365f6695e7dd5cdf3e180604530ed33b4";
        sha256 = "sha256-4vhDuZ7OZaZmKKrnDpxLZZpGIJvAeMtK6FKLJYUtAdw=";
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
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.DarwinTools
  ];

  buildFlags = [
    "dragonfly"
    "dragonflybin"
    "bin"
    "fstbin"
    "lmbin"
  ];

  preConfigure = ''
    patchShebangs src
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    # On macOS with Accelerate, LAPACK symbols don't have LAPACK_ prefix
    substituteInPlace src/matrix/cblas-wrappers.h \
      --replace-warn LAPACK_stptri stptri_ \
      --replace-warn LAPACK_dtptri dtptri_ \
      --replace-warn LAPACK_sgetrf sgetrf_ \
      --replace-warn LAPACK_dgetrf dgetrf_ \
      --replace-warn LAPACK_sgetri sgetri_ \
      --replace-warn LAPACK_dgetri dgetri_ \
      --replace-warn LAPACK_sgesvd sgesvd_ \
      --replace-warn LAPACK_dgesvd dgesvd_ \
      --replace-warn LAPACK_ssptri ssptri_ \
      --replace-warn LAPACK_dsptri dsptri_ \
      --replace-warn LAPACK_ssptrf ssptrf_ \
      --replace-warn LAPACK_dsptrf dsptrf_
  ''
  + lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) ''
    # Remove SSE flags for ARM64 on macOS
    substituteInPlace src/makefiles/darwin.mk \
      --replace-fail '-msse -msse2' ' '
  '';

  configurePhase = ''
    patchShebangs src
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    # On macOS with Accelerate, LAPACK symbols don't have LAPACK_ prefix
    substituteInPlace src/matrix/cblas-wrappers.h \
      --replace-warn LAPACK_stptri stptri_ \
      --replace-warn LAPACK_dtptri dtptri_ \
      --replace-warn LAPACK_sgetrf sgetrf_ \
      --replace-warn LAPACK_dgetrf dgetrf_ \
      --replace-warn LAPACK_sgetri sgetri_ \
      --replace-warn LAPACK_dgetri dgetri_ \
      --replace-warn LAPACK_sgesvd sgesvd_ \
      --replace-warn LAPACK_dgesvd dgesvd_ \
      --replace-warn LAPACK_ssptri ssptri_ \
      --replace-warn LAPACK_dsptri dsptri_ \
      --replace-warn LAPACK_ssptrf ssptrf_ \
      --replace-warn LAPACK_dsptrf dsptrf_
  ''
  + lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) ''
    # Remove SSE flags for ARM64 on macOS
    substituteInPlace src/makefiles/darwin.mk \
      --replace-fail '-msse -msse2' ' '
  ''
  + ''
    cd src
    ./configure --shared --fst-root="${old-openfst}" --use-cuda=no --openblas-root="${openblas}" --mathlib=OPENBLAS
  '';

  installPhase = ''
    find . -type f -name "*.o" -print0 | xargs -0 rm -f
    mkdir -p $out/{bin,lib}
    cp lib/* $out/lib/
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf \
      --set-rpath "${lib.makeLibraryPath buildInputs}:$out/lib" \
      $out/lib/*
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    # On macOS, use install_name_tool instead of patchelf
    for f in $out/lib/*.dylib; do
      install_name_tool -id $f $f
      install_name_tool -add_rpath ${lib.makeLibraryPath buildInputs} $f || true
      install_name_tool -add_rpath $out/lib $f || true
    done
  ''
  + '''';

  meta = with lib; {
    description = "Speech Recognition Toolkit";
    homepage = "https://kaldi-asr.org";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
