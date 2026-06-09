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
    clusters="$(env AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" aws ssm get-parameter \
        --name /eks/current_cluster --query Parameter.Value --output text)"

    printf 'export EMED_PLATFORM_INTEGRATIONS=%s\n' "$platform_integrations"
    printf 'export EMED_PLATFORM_SERVICES=%s\n' "$platform_services"
    printf 'export AWS_PROFILE=%s\n' "$aws_profile"
    printf 'export AWS_REGION=%s\n' "$aws_region"
    printf 'export KUBECONFIG=%s\n' "$kubeconfig"
    printf '%s --region %s\n' "$awsEksUpdateKubeconfig" "$aws_region"
    if [[ "$clusters" == *","* ]]; then
      printf "(!) Multiple clusters are enabled in this region; select one with kubectl config use-context %s\n" "$clusters"
    else
      printf 'kubectl config use-context %s' "$aws_profile--$clusters"
    fi
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
  home.packages = [
    emedHelmTemplate
  ]
  ++ (with pkgs; [
    github-cli-tools

    crane
    skopeo
  ])
  ++ (
    if (!isDarwin) then
      (with pkgs; [
        claude-code
        codex
        code-cursor
        cursor-cli
      ])
    else
      [ ]
  );

  home.sessionPath = [
    "$HOME/Code/emed-labs/engineer-toolbox/bin"
    "$HOME/Code/emed-labs/nix/bin"
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK =
      if isDarwin then
        "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      else
        "$HOME/.1password/agent.sock";
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
        format = "yaml";
        key = "finicky/config";
        path = "${config.home.homeDirectory}/.finicky.js";
      };

      aws-config = {
        format = "yaml";
        key = "aws/config";
        path = "${config.home.homeDirectory}/.aws/config";
      };

      npmrc = {
        format = "yaml";
        key = "npm/rc";
        path = "${config.home.homeDirectory}/.npmrc";
      };
      yarnrc = {
        format = "yaml";
        key = "yarn/rc";
        path = "${config.home.homeDirectory}/.yarnrc.yml";
      };

      emed-mini-platforms = {
        format = "yaml";
        key = "miniplatforms/config";
        path = "${config.home.homeDirectory}/.config/emed/miniplatforms.yaml";
      };

      grafana-cloud-url.key = "grafana/cloud/url";
      grafana-cloud-service-account-token.key = "grafana/cloud/service-account-token";

      coralogix-uk-nonprod-api-key = {
        format = "yaml";
        key = "coralogix/uk-nonprod";
      };
      coralogix-uk-prod-api-key = {
        format = "yaml";
        key = "coralogix/uk-prod";
      };
      coralogix-us-nonprod-api-key = {
        format = "yaml";
        key = "coralogix/us-nonprod";
      };
      coralogix-us-prod-api-key = {
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
        "Authorization: Bearer @coralogix-uk-nonprod-api-key@"
      ];
    };
    coralogix-uk-prod = {
      command = "mcp-remote";
      args = [
        "https://api.eu2.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @coralogix-uk-prod-api-key@"
      ];
    };
    coralogix-us-nonprod = {
      command = "mcp-remote";
      args = [
        "https://api.us1.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @coralogix-us-nonprod-api-key@"
      ];
    };
    coralogix-us-prod = {
      command = "mcp-remote";
      args = [
        "https://api.us1.coralogix.com/mgmt/api/v1/mcp"
        "--header"
        "Authorization: Bearer @coralogix-us-prod-api-key@"
      ];
    };

    github = {
      command = getExe pkgs.github-mcp-server;
      args = [ "stdio" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "@github-mcp-token@";
    };

    grafana-cloud = {
      command = getExe pkgs.mcp-grafana;
      env = {
        GRAFANA_URL = "@grafana-cloud-url@";
        GRAFANA_SERVICE_ACCOUNT_TOKEN = "@grafana-cloud-service-account-token@";
      };
    };

    scalr = {
      url = "https://scalr.io/mcp";
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
