{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.stateVersion = "24.05";

  home.username = "lukecarrier";
  home.homeDirectory = "/home/lukecarrier";

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
  
  home.packages = with pkgs; [
    docker-cli-tools
    ungoogled-chromium
    monaspace-fonts
    stklos
    nautilus
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = config.home.sessionVariables.BITWARDEN_SSH_AUTH_SOCK;
  };

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  sops.secrets.aws-config = {
    sopsFile = ../../secrets/personal.yaml;
    format = "yaml";
    key = "aws/config";
    path = "${config.home.homeDirectory}/.aws/config";
  };

  programs.home-manager.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        app = "org.gnome.Nautilus";
      in {
        "x-scheme-handler/file" = app;
      };
  };

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
