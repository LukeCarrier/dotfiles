{
  lib,
  pkgs,
  inputs,
  ...
}:
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
    ../../../../component/1password/home.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/spec-kit/spec-kit.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/helix/helix.nix
    ../../../../component/vscode/vscode.nix
    ../../../../component/zed/zed.nix
    ../../../../component/vim/vim.nix
    ../../../../component/gnupg/gnupg.nix
    ../../../../component/git/git.nix
    ../../../../component/jj/jj.nix
    ../../../../component/zoxide/zoxide.nix
    ../../../../component/espanso/espanso.nix
    ../../../../component/wezterm/wezterm.nix
    ../../../../component/aws/aws.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
    ../../../../component/lima/lima.nix
    ../../../../component/rust/cargo.nix
  ];

  home.stateVersion = "24.05";

  home.username = "luke.carrier";
  home.homeDirectory = "/Users/luke.carrier";

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "onepassword-password-manager"
      "vault"
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
      "vscode-extension-ms-vscode-remote-remote-containers"
    ];

  # FIXME: should we be keeping all of this cruft in a devShell?
  home.packages = with pkgs; [ docker-cli-tools ];

  sops.secrets.opencode-github-token.sopsFile = pkgs.lib.mkForce ../../../../secrets/employer-emed.yaml;

  opencode.mcpConfigurations = {
    github = {
      type = "local";
      command = [ "${pkgs.github-mcp-server}/bin/github-mcp-server" "stdio" ];
      url = null;
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
      };
      secrets = {
        "@TOKEN@" = config.sops.placeholder.opencode-github-token;
      };
    };
  };
}
