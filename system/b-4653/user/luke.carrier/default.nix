{
  lib,
  pkgs,
  inputs,
  permittedInsecurePackages,
  ...
}:
let
  inherit (lib) getExe;
  username = "luke.carrier";
  homeDirectory = "/Users/${username}";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../../../platform/darwin/home.nix
    ../../../../employer/emed/emed.nix
    ../../../../component/shell-essential/shell-essential.nix
    ../../../../component/homebrew/homebrew.nix
    ../../../../component/fonts/fonts.nix
    ../../../../component/readline/readline.nix
    ../../../../component/bash/bash.nix
    ../../../../component/fish/fish.nix
    ../../../../component/fish/default.nix
    ../../../../component/zsh/zsh.nix
    ../../../../component/direnv/direnv.nix
    ../../../../component/firefox/firefox.nix
    ../../../../component/rift/rift.nix
    ../../../../component/1password/1password.nix
    ../../../../component/goose/goose.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/helix/helix.nix
    ../../../../component/zed/zed.nix
    ../../../../component/vim/vim.nix
    ../../../../component/gnupg/gnupg.nix
    ../../../../component/git/git.nix
    ../../../../component/jj/jj.nix
    ../../../../component/zoxide/zoxide.nix
    ../../../../component/espanso/espanso.nix
    ../../../../component/ghostty/ghostty.nix
    ../../../../component/aws/aws.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
    ../../../../component/lima/lima.nix
    ../../../../component/rust/cargo.nix
  ];

  home = {
    stateVersion = "24.05";

    username = "luke.carrier";
    homeDirectory = homeDirectory;
  };

  sops.defaultSopsFile = ../../../../secrets/employer-emed.yaml;

  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "claude-code"
        "onepassword-password-manager"
        "vscode-extension-github-copilot"
        "vscode-extension-github-copilot-chat"
        "vscode-extension-ms-vscode-remote-remote-containers"
      ];

    inherit permittedInsecurePackages;
  };
}
