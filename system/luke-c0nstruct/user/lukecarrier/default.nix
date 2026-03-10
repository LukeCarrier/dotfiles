{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe' getName;
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
    #../../../../component/rift/rift.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/helix/helix.nix
    ../../../../component/vim/vim.nix
    ../../../../component/zed/zed.nix
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

  home.stateVersion = "25.11";

  home.username = "lukecarrier";
  home.homeDirectory = "/Users/lukecarrier";

  nixpkgs.config = {
    allowBroken = true;
    allowUnsupportedSystem = true;

    allowUnfreePredicate =
      pkg:
      builtins.elem (getName pkg) [
        "terraform"
      ];
  };

  home.packages = with pkgs; [
    docker-cli-tools
  ];

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
