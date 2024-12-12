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
      "jetbrains-toolbox"
      "code"
      "vscode"
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
    ];

  home.packages = with pkgs; [
    bitwarden-cli
    bw-cli-tools
    btop
    gh
    freshfetch
    jq
    ungoogled-chromium
    jetbrains-toolbox
    gnome-network-displays
    monaspace-fonts
    stklos
    nautilus
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  sops.secrets.aws-config = {
    sopsFile = ../../secrets/personal.yaml;
    format = "yaml";
    key = "aws/config";
    path = "${config.home.homeDirectory}/.aws/config";
  };

  programs.home-manager.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
    extensions = with pkgs.vscode-extensions; [
      github.copilot
      github.copilot-chat
    ];
  };
}
