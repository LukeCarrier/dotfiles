{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe';
  inherit (pkgs.stdenv) isDarwin;
  selectMiniplatform = pkgs.writeShellScriptBin "emed-mini-platform" ''
    awsEksUpdateKubeconfig="${getExe' pkgs.aws-cli-tools "aws-eks-update-kubeconfig"}"
    fzf="${getExe pkgs.fzf}"
    yq="${getExe pkgs.yq-go}"
    platforms="$HOME/.config/emed/miniplatforms.yaml"

    index="$("$yq" eval -r '. | keys[]' "$platforms" | \
      "$fzf" --preview "'$yq' eval '.[\"{}\"]' '$platforms'")"
    platform_integrations="$("$yq" eval -r ".$index.emed.platformIntegrations" "$platforms")"
    platform_services="$("$yq" eval -r ".$index.emed.platformServices" "$platforms")"
    aws_profile="$("$yq" eval -r ".$index.aws.profile" "$platforms")"
    aws_region="$("$yq" eval -r ".$index.aws.region" "$platforms")"
    env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws sts get-caller-identity >&2 || \
      env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws sso login >&2
    kubeconfig="$(printf %s/.kube/configs/%s "$HOME" "$("$yq" eval -r ".$index.kubeconfig" "$platforms")")"
    cluster="$(env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws ssm get-parameter \
        --name /eks/current_cluster --query Parameter.Value --output text)"

    printf 'export EMED_PLATFORM_INTEGRATIONS=%s\n' "$platform_integrations"
    printf 'export EMED_PLATFORM_SERVICES=%s\n' "$platform_services"
    printf 'export AWS_PROFILE=%s\n' "$aws_profile"
    printf 'export AWS_REGION=%s\n' "$aws_region"
    printf 'export KUBECONFIG=%s\n' "$kubeconfig"
    printf '%s --region %s\n' "$awsEksUpdateKubeconfig" "$aws_region"
    printf 'kubectl config use-context %s' "$aws_profile--$cluster"
  '';
  emedHelmTemplate = pkgs.writeShellApplication {
    name = "emed-helm-template";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      git
      gnused
      gawk
      kubernetes-helm
      yq-go
    ];
    text = builtins.readFile ./bin/emed-helm-template;
  };
in
{
  home.packages =
    [ emedHelmTemplate ]
    ++ (with pkgs; [
      github-cli-tools

      crane
      docker-cli-tools
      skopeo
    ])
    ++ (if (!isDarwin) then (with pkgs; [
      claude-code
      codex
      code-cursor
      cursor-cli
    ]) else [ ]);

  home.sessionPath = [
    "$HOME/Code/emed-labs/engineer-toolbox/bin"
    "$HOME/Code/emed-labs/nix/bin"
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK =
      if isDarwin
      then "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      else "$HOME/.1password/agent.sock";
  };

  sops = {
    # sops-nix is pretty weird, in that it won't resolve any of these values
    # during the Nix evaluation and will install a helper to do it when we
    # switch to the new generation. If secrets don't show up shortly after
    # doing this, check the logs for that helper tool, which can be found at:
    # ~/Libary/Logs/SopsNix/std{out,err}
    age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

    secrets = {
      finicky-config = {
        sopsFile = ../../secrets/employer-emed.yaml;
        format = "yaml";
        key = "finicky/config";
        path = "${config.home.homeDirectory}/.finicky.js";
      };

      aws-config = {
        sopsFile = ../../secrets/employer-emed.yaml;
        format = "yaml";
        key = "aws/config";
        path = "${config.home.homeDirectory}/.aws/config";
      };

      npmrc = {
        sopsFile = ../../secrets/employer-emed.yaml;
        format = "yaml";
        key = "npm/rc";
        path = "${config.home.homeDirectory}/.npmrc";
      };
      yarnrc = {
        sopsFile = ../../secrets/employer-emed.yaml;
        format = "yaml";
        key = "yarn/rc";
        path = "${config.home.homeDirectory}/.yarnrc.yml";
      };

      emed-mini-platforms = {
        sopsFile = ../../secrets/employer-emed.yaml;
        format = "yaml";
        key = "miniplatforms/config";
        path = "${config.home.homeDirectory}/.config/emed/miniplatforms.yaml";
      };

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
  };

  programs.mcp.servers = {
    atlassian = {
      url = "https://mcp.atlassian.com/v1/mcp";
    };

    coralogix-uk-nonprod = {
      command = "mcp-remote";
      args = [
        "https://api.eu2.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_UK_NONPROD_API_KEY@"
      ];
    };
    coralogix-uk-prod = {
      command = "mcp-remote";
      args = [
        "https://api.eu2.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_UK_PROD_API_KEY@"
      ];
    };
    coralogix-us-nonprod = {
      command = "mcp-remote";
      args = [
        "https://api.us1.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_US_NONPROD_API_KEY@"
      ];
    };
    coralogix-us-prod = {
      command = "mcp-remote";
      args = [
        "https://api.us1.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @CORALOGIX_US_PROD_API_KEY@"
      ];
    };

    github = {
      command = getExe pkgs.github-mcp-server;
      args = [ "stdio" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "@TOKEN@";
    };

    grafana-cloud = {
      command = getExe pkgs.mcp-grafana;
      env = {
        GRAFANA_URL = "@URL@";
        GRAFANA_SERVICE_ACCOUNT_TOKEN = "@SERVICE_ACCOUNT_TOKEN@";
      };
    };

    slack = {
      url = "https://mcp.slack.com/mcp";
    };
  };

  programs.bash.initExtra = ''
    emed-mini-platform() {
      eval "$(${getExe selectMiniplatform})"
    }
  '';
  programs.fish = {
    functions.emed-mini-platform = ''
      ${getExe selectMiniplatform} | source
    '';
    shellInit = "";
  };
  programs.zsh.initContent = config.programs.bash.initExtra;

  programs.librewolf.profiles.default =
    let
      browserActions = {
        "1password" = "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action";
      };
    in
    {
      containers = {
        eMed = {
          id = 2;
          color = "purple";
          icon = "briefcase";
        };
        TELUS = {
          id = 3;
          color = "orange";
          icon = "briefcase";
        };
      };
      extensions.packages = lib.mkForce (
        with pkgs.nur.repos.rycee.firefox-addons;
        [
          istilldontcareaboutcookies
          multi-account-containers
          markdownload
          onepassword-password-manager
          read-aloud
          refined-github
          ublock-origin
          vimium
        ]
      );
      settings."browser.uiCustomization.navBarWhenVerticalTabs" = lib.mkForce [
        "sidebar-button"
        "back-button"
        "forward-button"
        "stop-reload-button"
        "customizableui-special-spring3"
        "urlbar-container"
        "vertical-spacer"
        "alltabs-button"
        "firefox-view-button"
        "unified-extensions-button"
        browserActions."1password"
      ];
    };
}
