{ lib, pkgs }:
let
  inherit (pkgs) stdenv;
  inherit (lib) getExe getExe';

  mkToolVersions =
    name: commands:
    let
      versionScript = pkgs.writeShellScript "${name}-version-script" ''
        {
          ${commands}
        } >>"$out"
      '';
    in
    pkgs.runCommand "${name}-versions" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } versionScript;

  mkCorepack =
    nodejs:
    stdenv.mkDerivation {
      pname = "corepack";
      version = "${nodejs.version}";
      buildInputs = [ nodejs ];
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        corepack enable --install-directory=$out/bin
      '';
    };

  mkNodeDevShell =
    name: nodejs:
    let
      inherit (pkgs) bun;
      pnpm = pkgs.pnpm.override { inherit nodejs; };
      typescript-language-server = pkgs.typescript-language-server.override { inherit nodejs; };
      yarn = pkgs.yarn.override { inherit nodejs; };
      toolVersions = mkToolVersions name ''
        printf "bun %s\n" "$(${getExe bun} --version 2>&1 | head -n 1)"
        printf "node %s\n" "$(${getExe nodejs} --version 2>&1 | head -n 1)"
        printf "pnpm %s\n" "$(${getExe pnpm} --version 2>&1 | head -n 1)"
        printf "typescript-language-server %s\n" "$(${getExe typescript-language-server} --version 2>&1 | head -n 1)"
        printf "yarn %s\n" "$(${getExe yarn} --version 2>&1 | head -n 1)"
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = [
        bun
        nodejs
        (mkCorepack nodejs)
        pnpm
        typescript-language-server
        yarn
      ];
    };

  mkRubyDevShell =
    name: ruby:
    let
      inherit (pkgs)
        bundler
        curl
        libyaml
        ;
      toolVersions = mkToolVersions name ''
        ${getExe bundler} --version
        ${getExe ruby} --version
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        export LD_LIBRARY_PATH=${curl.out}/lib:$LD_LIBRARY_PATH
        cat ${toolVersions}
      '';
      nativeBuildInputs = [
        bundler
        curl
        libyaml
        ruby
      ];
    };
in
{
  default =
    let
      inherit (lib) getExe getExe';
      inherit (pkgs)
        age
        git
        gnumake
        hydra-check
        jujutsu
        nh
        nil
        nixd
        nix-index
        nixfmt
        ssh-to-age
        sops
        treefmt
        ;
      toolVersions = mkToolVersions "default" ''
        printf "age %s\n" "$(${getExe age} --version 2>&1 | head -n 1)"
        ${getExe git} --version
        ${getExe jujutsu} --version
        ${getExe nh} --version
        ${getExe gnumake} --version | head -n 1
        ${getExe hydra-check} --version
        ${getExe nil} --version 2>&1 | head -n 1
        ${getExe nixd} --version 2>&1 | head -n 1
        ${getExe' nix-index "nix-locate"} --version 2>&1 | head -n 1
        ${getExe nixfmt} --version 2>&1 | head -n 1
        ${getExe sops} --version 2>&1 | head -n 1
        ${getExe treefmt} --version 2>&1 | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = [
        age
        git
        gnumake
        hydra-check
        jujutsu
        nh
        nil
        nixd
        nix-index
        nixfmt
        ssh-to-age
        sops
        treefmt
      ];
    };

  cuda =
    let
      inherit (stdenv) cc;
      inherit (pkgs)
        git
        gitRepo
        gnupg
        autoconf
        curl
        procps
        gnumake
        util-linux
        m4
        gperf
        unzip
        cudatoolkit
        libGLU
        libGL
        freeglut
        zlib
        ncurses5
        binutils
        ;
      inherit (pkgs.linuxPackages) nvidia_x11;
      inherit (pkgs.xorg)
        libXi
        libXmu
        libXext
        libX11
        libXv
        libXrandr
        ;
      toolVersions = mkToolVersions "cuda";
    in
    pkgs.mkShell {
      shellHook = ''
        export CUDA_PATH="${cudatoolkit}"
        export LD_LIBRARY_PATH="${nvidia_x11}/lib:${ncurses5}/lib"
        export EXTRA_LDFLAGS="-L/lib -L${nvidia_x11}/lib"
        export EXTRA_CCFLAGS="-I/usr/include"
      '';
      buildInputs = [
        cc
        git
        gitRepo
        gnupg
        autoconf
        curl
        procps
        gnumake
        util-linux
        m4
        gperf
        unzip
        cudatoolkit
        nvidia_x11
        libGLU
        libGL
        freeglut
        zlib
        libXi
        libXmu
        libXext
        libX11
        libXv
        libXrandr
        ncurses5
        binutils
      ];
    };

  goDev =
    let
      inherit (pkgs)
        delve
        go
        golangci-lint
        golangci-lint-langserver
        gopls
        gnumake
        ;
      toolVersions = mkToolVersions "goDev" ''
        ${getExe delve} version 2>&1 | head -n 1
        ${getExe go} version
        ${getExe golangci-lint} --version 2>&1 | head -n 1
        ${getExe gopls} version 2>&1 | head -n 1
        ${getExe gnumake} --version | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = [
        delve
        gnumake
        go
        golangci-lint
        golangci-lint-langserver
        gopls
      ];
    };

  node22Dev = mkNodeDevShell "node22Dev" pkgs.nodejs;
  node24Dev = mkNodeDevShell "node24Dev" pkgs.nodejs_24;

  kotlinDev =
    let
      inherit (pkgs)
        kotlin
        kotlin-language-server
        ;
      toolVersions = mkToolVersions "kotlinDev" ''
        ${getExe kotlin} -version 2>&1
        ${getExe kotlin-language-server} --version
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = [
        kotlin
        kotlin-language-server
      ];
    };

  pythonDev =
    let
      inherit (pkgs) python314;
      inherit (pkgs.python314Packages)
        jedi-language-server
        python-lsp-server
        ruff
        ;
      toolVersions = mkToolVersions "pythonDev" ''
        ${getExe python314} --version
        ${getExe ruff} --version 2>&1 | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      packages = [
        python314
        jedi-language-server
        python-lsp-server
        ruff
      ];
    };

  ruby33Dev = mkRubyDevShell "ruby33Dev" pkgs.ruby_3_3;
  ruby34Dev = mkRubyDevShell "ruby33Dev" pkgs.ruby;
  ruby40Dev = mkRubyDevShell "ruby33Dev" pkgs.ruby_4_0;

  rustDev =
    let
      inherit (pkgs.rust-bin.stable.latest) default;
      inherit (pkgs)
        lldb_19
        pkg-config
        rust-analyzer
        rustup
        ;

    toolVersions = mkToolVersions "rustDev" ''
        ${getExe' default "cargo"} --version
        ${getExe' default "rustc"} --version
        ${getExe lldb_19} --version | head -n 1
        ${getExe rust-analyzer} --version 2>&1 | head -n 1
        ${getExe rustup} --version 2>&1 | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
        default
        lldb_19
        pkg-config
        rust-analyzer
        rustup
      ];
    };
}
