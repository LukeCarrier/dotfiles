{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) getExe getExe';
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
    ../../../../component/ghostty/ghostty.nix
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

  sops.secrets = {
    opencode-github-token.sopsFile = pkgs.lib.mkForce ../../../../secrets/employer-emed.yaml;

    coralogix-uk-nonprod-api-key = {
      sopsFile = pkgs.lib.mkDefault ../../../../secrets/employer-emed.yaml;
      format = "yaml";
      key = "coralogix/uk-nonprod";
    };
    coralogix-uk-prod-api-key = {
      sopsFile = pkgs.lib.mkDefault ../../../../secrets/employer-emed.yaml;
      format = "yaml";
      key = "coralogix/uk-prod";
    };
    coralogix-us-nonprod-api-key = {
      sopsFile = pkgs.lib.mkDefault ../../../../secrets/employer-emed.yaml;
      format = "yaml";
      key = "coralogix/us-nonprod";
    };
    coralogix-us-prod-api-key = {
      sopsFile = pkgs.lib.mkDefault ../../../../secrets/employer-emed.yaml;
      format = "yaml";
      key = "coralogix/us-prod";
    };
  };

  opencode.mcpConfigurations = {
    container-use = {
      type = "local";
      command = [
        "${getExe' pkgs.container-use "container-use"}"
        "stdio"
      ];
    };
    github = {
      type = "local";
      command = [
        "${getExe pkgs.github-mcp-server}"
        "stdio"
      ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
      secrets."@TOKEN@" = config.sops.placeholder.opencode-github-token;
    };

    coralogix-uk-nonprod = {
      type = "local";
      command = [
        "mcp-remote"
        "https://api.eu2.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_UK_NONPROD_API_KEY@"
      ];
      secrets = {
        "@CORALOGIX_UK_NONPROD_API_KEY@" = config.sops.placeholder.coralogix-uk-nonprod-api-key;
      };
    };
    coralogix-uk-prod = {
      type = "local";
      command = [
        "mcp-remote"
        "https://api.eu2.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_UK_PROD_API_KEY@"
      ];
      secrets = {
        "@CORALOGIX_UK_PROD_API_KEY@" = config.sops.placeholder.coralogix-uk-prod-api-key;
      };
    };
    coralogix-us-nonprod = {
      type = "local";
      command = [
        "mcp-remote"
        "https://api.us1.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_US_NONPROD_API_KEY@"
      ];
      secrets = {
        "@CORALOGIX_US_NONPROD_API_KEY@" = config.sops.placeholder.coralogix-us-nonprod-api-key;
      };
    };
    coralogix-us-prod = {
      type = "local";
      command = [
        "mcp-remote"
        "https://api.us1.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_US_PROD_API_KEY@"
      ];
      secrets = {
        "@CORALOGIX_US_PROD_API_KEY@" = config.sops.placeholder.coralogix-us-prod-api-key;
      };
    };
  };
}
