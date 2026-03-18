{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) getExe getExe';
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
    ../../../../component/1password/home.nix
    ../../../../component/opencode/opencode.nix
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
  home.homeDirectory = homeDirectory;

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

  # Must be formatted exactly as follows or NVIDIA Sync will complain
  # that ~/.ssh/config is not writable
  programs.ssh.extraOptionOverrides = {
    Include = "\"${homeDirectory}/Library/Application Support/NVIDIA/Sync/config/ssh_config\"";
  };

  sops.secrets = {
    opencode-github-token.sopsFile = pkgs.lib.mkForce ../../../../secrets/employer-emed.yaml;

    grafana-cloud-url = {
      sopsFile = pkgs.lib.mkDefault ../../../../secrets/employer-emed.yaml;
      key = "grafana/cloud/url";
    };
    grafana-cloud-service-account-token = {
      sopsFile = pkgs.lib.mkDefault ../../../../secrets/employer-emed.yaml;
      key = "grafana/cloud/service-account-token";
    };

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
    atlassian = {
      enabled = false;
      type = "remote";
      url = "https://mcp.atlassian.com/v1/mcp";
    };

    coralogix-uk-nonprod = {
      enabled = false;
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
      enabled = false;
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
      enabled = false;
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
      enabled = false;
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

    github = {
      enabled = false;
      type = "local";
      command = [
        (getExe pkgs.github-mcp-server)
        "stdio"
      ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
      secrets."@TOKEN@" = config.sops.placeholder.opencode-github-token;
    };

    grafana-cloud = {
      enabled = false;
      type = "local";
      command = [ (getExe pkgs.mcp-grafana) ];
      env = {
        GRAFANA_URL = "@URL@";
        GRAFANA_SERVICE_ACCOUNT_TOKEN = "@SERVICE_ACCOUNT_TOKEN@";
      };
      secrets = {
        "@URL@" = config.sops.placeholder.grafana-cloud-url;
        "@SERVICE_ACCOUNT_TOKEN@" = config.sops.placeholder.grafana-cloud-service-account-token;
      };
    };

    slack = {
      enabled = false;
      type = "remote";
      url = "https://mcp.slack.com/mcp";
    };
  };
}
