{ config, ... }:
{
  home.stateVersion = "24.05";

  home.username = "luke.carrier";
  home.homeDirectory = "/Users/luke.carrier";

  home.sessionVariables = {
    EDITOR = "hx";
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
    key = ''finicky/config'';
    path = "${config.home.homeDirectory}/.finicky.js";
  };
}
