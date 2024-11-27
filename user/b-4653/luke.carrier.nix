{ config, lib, pkgs, ... }:
{
  home.stateVersion = "24.05";

  home.username = "luke.carrier";
  home.homeDirectory = "/Users/luke.carrier";

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vault"
  ];

  # FIXME: should we be keeping all of this cruft in a devShell?
  home.packages = with pkgs; [
    saml2aws
    docker-client
    kubectl krew kyverno
    vault
  ];

  home.sessionVariables = {
    EDITOR = "hx";
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # sops-nix is pretty weird, in that it won't resolve any of these values
  # diring the Nix evaluation and will install a helper to do it when we switch
  # to the new generation. If secrets don't show up shortly after doing this,
  # check the logs for that helper tool, which can be found at:
  # ~/Libary/Logs/SopsNix/std{out,err}
  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  sops.secrets.finicky-config = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "finicky/config";
    path = "${config.home.homeDirectory}/.finicky.js";
  };

  sops.secrets.aws-config = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "aws/config";
    path = "${config.home.homeDirectory}/.aws/config";
  };
  sops.secrets.aws-saml2aws = {
    sopsFile = ../../secrets/employer-emed.yaml;
    format = "yaml";
    key = "aws/saml2aws/config";
    path = "${config.home.homeDirectory}/.saml2aws";
  };

  home.sessionPath = [
    "$HOME/.krew/bin"
  ];

  programs.bash.initExtra = "eval $(kubectl shell_ctx hook bash)";
  programs.fish.shellInit = "kubectl shell_ctx hook fish | source";
  programs.zsh.initExtra = "eval $(kubectl shell_ctx hook zsh)";
}
