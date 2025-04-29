{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.stateVersion = "24.05";

  home.username = "luke.carrier";
  home.homeDirectory = "/Users/luke.carrier";

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vault"
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
    ];

  # FIXME: should we be keeping all of this cruft in a devShell?
  home.packages =
    (with pkgs; [
      saml2aws
      docker-client
      docker-credential-helpers
      vault

      csvlens
      ripgrep
      tv
      docker-cli-tools

      dotfiles-meta
    ])
    ++ (with pkgs.unixtools; [
      watch
    ]);
}
