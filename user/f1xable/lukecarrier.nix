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
      "vscode-extension-ms-vsliveshare-vsliveshare"
    ];

  home.packages = with pkgs; [
    btop
    docker-cli-tools
    gh
    freshfetch
    jq
    ungoogled-chromium
    gnome-network-displays
    monaspace-fonts
    stklos
    nautilus

    dotfiles-meta
    psmisc
    ripgrep
    watchexec
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

  xdg.mimeApps.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
