{
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../../../component/shell-essential/shell-essential.nix
    ../../../../component/homebrew/homebrew.nix
    ../../../../component/fonts/fonts.nix
    ../../../../component/readline/readline.nix
    ../../../../component/bash/bash.nix
    ../../../../component/fish/fish.nix
    ../../../../component/zsh/zsh.nix
    ../../../../component/fish/default.nix
    ../../../../component/direnv/direnv.nix
    ../../../../component/firefox/firefox.nix
    ../../../../component/ollama/ollama.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/helix/helix.nix
    ../../../../component/vscode/vscode.nix
    ../../../../component/vim/vim.nix
    ../../../../component/gnupg/gnupg.nix
    ../../../../component/git/git.nix
    ../../../../component/jj/jj.nix
    ../../../../component/zoxide/zoxide.nix
    # ../../../../component/espanso/espanso.nix
    ../../../../component/alacritty/alacritty.nix
    ../../../../component/wezterm/wezterm.nix
    ../../../../component/aws/aws.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
    ../../../../component/lima/lima.nix
    ../../../../component/rust/cargo.nix
  ];

  home.stateVersion = "24.05";

  home.username = "lukecarrier";
  home.homeDirectory = "/Users/lukecarrier";

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "code"
      "terraform"
      "vscode"
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
      "vscode-extension-ms-vscode-remote-remote-containers"
      "vscode-extension-ms-vsliveshare-vsliveshare"
    ];
}
