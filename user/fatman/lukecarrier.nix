{ lib, ... }:
{
  home.stateVersion = "24.05";

  home.username = "lukecarrier";
  home.homeDirectory = "/Users/lukecarrier";

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
}
