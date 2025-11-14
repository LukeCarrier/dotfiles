{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../../../component/shell-essential/shell-essential.nix
    ../../../../component/bitwarden/bitwarden.nix
    ../../../../component/homebrew/homebrew.nix
    ../../../../component/fonts/fonts.nix
    ../../../../component/readline/readline.nix
    ../../../../component/bash/bash.nix
    ../../../../component/fish/fish.nix
    ../../../../component/zsh/zsh.nix
    ../../../../component/fish/default.nix
    ../../../../component/direnv/direnv.nix
    ../../../../component/firefox/firefox.nix
    ../../../../component/rift/rift.nix
    ../../../../component/dragonfly/dragonfly.nix
    ../../../../component/container-use/container-use.nix
    ../../../../component/ollama/ollama.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/spec-kit/spec-kit.nix
    ../../../../component/claude-code/claude-code.nix
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
    ../../../../component/espanso/espanso.nix
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

  nixpkgs.config = {
    allowBroken = true;
    allowUnsupportedSystem = true;

    # XXX: what the fuck is wrong with this!??!??!??!?!
    allowBrokenPredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "python3.13-pynput-1.8.1"
      ];

    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "claude-code"
        "code"
        "terraform"
        "vscode"
        "vscode-extension-github-copilot"
        "vscode-extension-github-copilot-chat"
        "vscode-extension-ms-vscode-remote-remote-containers"
        "vscode-extension-ms-vsliveshare-vsliveshare"
      ];
  };

  home.packages = with pkgs; [
    docker-cli-tools
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";
}
