{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe' getName;
  username = "lukecarrier";
  homeDirectory = "/Users/${username}";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../../../platform/darwin/home.nix
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
    ../../../../component/ollama/ollama.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/claude-code/claude-code.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/helix/helix.nix
    ../../../../component/vscode/vscode.nix
    ../../../../component/vim/vim.nix
    ../../../../component/zed/zed.nix
    ../../../../component/gnupg/gnupg.nix
    ../../../../component/git/git.nix
    ../../../../component/jj/jj.nix
    ../../../../component/zoxide/zoxide.nix
    ../../../../component/espanso/espanso.nix
    ../../../../component/alacritty/alacritty.nix
    ../../../../component/ghostty/ghostty.nix
    ../../../../component/wezterm/wezterm.nix
    ../../../../component/aws/aws.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
    ../../../../component/lima/lima.nix
    ../../../../component/rust/cargo.nix
  ];

  home.stateVersion = "24.05";

  home.username = "lukecarrier";
  home.homeDirectory = homeDirectory;

  nixpkgs.config = {
    allowBroken = true;
    allowUnsupportedSystem = true;

    allowUnfreePredicate =
      pkg:
      builtins.elem (getName pkg) [
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

  # Must be formatted exactly as follows or NVIDIA Sync will complain
  # that ~/.ssh/config is not writable
  programs.ssh.extraOptionOverrides = {
    Include = "\"${homeDirectory}/Library/Application Support/NVIDIA/Sync/config/ssh_config\"";
  };

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  opencode.mcpConfigurations = {
    excalidraw = {
      type = "local";
      command = [ (getExe' pkgs.excalidraw-mcp-app "excalidraw-mcp-app") "--stdio" ];
    };
    github = {
      type = "local";
      command = [ (getExe pkgs.github-mcp-server) "stdio" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
      secrets."@TOKEN@" = config.sops.placeholder.opencode-github-token;
    };
  };
}
