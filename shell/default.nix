{ pkgs }:
{
  default = pkgs.mkShell {
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

  goDev = pkgs.mkShell {
    shellHook = ''
      echo -n "dlv "; dlv version | awk '/Version/{print $2}'
      go version
      echo -n "golangci-lint "; golangci-lint --version
      make --version | head -n 1
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

  nodeDev = pkgs.mkShell {
    shellHook = ''
      echo -n "node "; node --version
      echo -n "pnpm "; pnpm --version
      echo -n "yarn "; yarn --version
    '';
    nativeBuildInputs = with pkgs; [
      bun
      nodejs
      pnpm
      typescript-language-server
      yarn
    ];
  };

  kotlinDev = pkgs.mkShell {
    shellHook = ''
      kotlin -version
    '';
    nativeBuildInputs = with pkgs; [
      kotlin
      kotlin-language-server
    ];
  };

  pythonDev = pkgs.mkShell {
    shellHook = ''
      python --version
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

  rustDev = pkgs.mkShell {
    shellHook = ''
      cargo --version
      rustc --version
    '';
    nativeBuildInputs = with pkgs; [
      lldb_19
      pkg-config
      rust-analyzer
      rust-bin.stable.latest.default
    ];
  };
}
