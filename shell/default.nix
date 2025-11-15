{ pkgs }:
let
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

  mkNodeDevShell =
    name: nodejs:
    let
      toolVersions = mkToolVersions name ''
        printf "bun %s\n" "$(${pkgs.bun}/bin/bun --version 2>&1 | head -n 1)"
        printf "node %s\n" "$(${nodejs}/bin/node --version 2>&1 | head -n 1)"
        printf "pnpm %s\n" "$(${
          pkgs.pnpm.override { inherit nodejs; }
        }/bin/pnpm --version 2>&1 | head -n 1)"
        printf "typescript-language-server %s\n" "$(${
          pkgs.typescript-language-server.override { inherit nodejs; }
        }/bin/typescript-language-server --version 2>&1 | head -n 1)"
        printf "yarn %s\n" "$(${
          pkgs.yarn.override { inherit nodejs; }
        }/bin/yarn --version 2>&1 | head -n 1)"
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = [
        pkgs.bun
        nodejs
        (pkgs.pnpm.override { inherit nodejs; })
        (pkgs.typescript-language-server.override { inherit nodejs; })
        (pkgs.yarn.override { inherit nodejs; })
      ];
    };
in
{
  default =
    let
      toolVersions = mkToolVersions "default" ''
        printf "age %s\n" "$(${pkgs.age}/bin/age --version 2>&1 | head -n 1)"
        ${pkgs.gnumake}/bin/make --version | head -n 1
        ${pkgs.nil}/bin/nil --version 2>&1 | head -n 1
        ${pkgs.nixd}/bin/nixd --version 2>&1 | head -n 1
        ${pkgs.nix-index}/bin/nix-locate --version 2>&1 | head -n 1
        ${pkgs.nixfmt-rfc-style}/bin/nixfmt --version 2>&1 | head -n 1
        ${pkgs.sops}/bin/sops --version 2>&1 | head -n 1
        ${pkgs.treefmt}/bin/treefmt --version 2>&1 | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
        age
        gnumake
        nil
        nixd
        nix-index
        nixfmt-rfc-style
        ssh-to-age
        sops
        treefmt
      ];
    };

  goDev =
    let
      toolVersions = mkToolVersions "goDev" ''
        ${pkgs.delve}/bin/dlv version 2>&1 | head -n 1
        ${pkgs.go}/bin/go version
        ${pkgs.golangci-lint}/bin/golangci-lint --version 2>&1 | head -n 1
        ${pkgs.gopls}/bin/gopls version 2>&1 | head -n 1
        ${pkgs.gnumake}/bin/make --version | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
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
      toolVersions = mkToolVersions "kotlinDev" ''
        ${pkgs.kotlin}/bin/kotlin -version 2>&1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
        kotlin
        kotlin-language-server
      ];
    };

  pythonDev =
    let
      toolVersions = mkToolVersions "pythonDev" ''
        ${pkgs.python314}/bin/python --version
        ${pkgs.python312Packages.ruff}/bin/ruff --version 2>&1 | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      packages =
        (with pkgs; [
          python314
        ])
        ++ (with pkgs.python312Packages; [
          jedi-language-server
          python-lsp-server
          ruff
        ]);
    };

  rustDev =
    let
      toolVersions = mkToolVersions "rustDev" ''
        ${pkgs.rust-bin.stable.latest.default}/bin/cargo --version
        ${pkgs.rust-bin.stable.latest.default}/bin/rustc --version
        ${pkgs.lldb_19}/bin/lldb --version | head -n 1
        ${pkgs.rust-analyzer}/bin/rust-analyzer --version 2>&1 | head -n 1
      '';
    in
    pkgs.mkShell {
      shellHook = ''
        cat ${toolVersions}
      '';
      nativeBuildInputs = with pkgs; [
        lldb_19
        pkg-config
        rust-analyzer
        rust-bin.stable.latest.default
      ];
    };
}
