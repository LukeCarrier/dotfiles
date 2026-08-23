{
  config,
  lib,
  pkgs,
  inputs,
  permittedInsecurePackages,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.niri
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.sops-nix.homeManagerModules.sops
    inputs.vicinae.homeManagerModules.default
    ../../../../component/shell-essential/shell-essential.nix
    ../../../../component/fonts/fonts.nix
    ../../../../component/readline/readline.nix
    ../../../../component/kanshi/kanshi.nix
    ../../../../component/gnome-headless/gnome-headless.nix
    ../../../../component/vicinae/vicinae.nix
    ../../../../component/ashell/ashell.nix
    ../../../../component/swayidle/swayidle.nix
    ../../../../component/swaylock/swaylock.nix
    ../../../../component/wpaperd/wpaperd.nix
    ../../../../component/mako/mako.nix
    ../../../../component/niri/niri.nix
    ../../../../component/bash/bash.nix
    ../../../../component/fish/fish.nix
    ../../../../component/fish/default.nix
    ../../../../component/zsh/zsh.nix
    ../../../../component/direnv/direnv.nix
    ../../../../component/firefox/firefox.nix
    ../../../../component/bitwarden/bitwarden.nix
    ../../../../component/handy/nixos-home.nix
    ../../../../component/agentkit/agentkit.nix
    ../../../../component/codex/codex.nix
    ../../../../component/goose/goose.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/pi/pi.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/coder/coder.nix
    ../../../../component/helix/helix.nix
    ../../../../component/vim/vim.nix
    ../../../../component/zed/zed.nix
    ../../../../component/gnupg/gnupg.nix
    ../../../../component/git/git.nix
    ../../../../component/jj/jj.nix
    ../../../../component/zoxide/zoxide.nix
    ../../../../component/ghostty/ghostty.nix
    ../../../../component/rust/cargo.nix
    ../../../../component/aws/aws.nix
    ../../../../component/docker/docker.nix
    ../../../../component/helm/helm.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
    ../../../../component/minikube/minikube.nix
  ];

  home = {
    stateVersion = "24.05";

    username = "lukecarrier";
    homeDirectory = "/home/lukecarrier";
  };

  sops.defaultSopsFile = ../../../../secrets/personal.yaml;

  nixpkgs.config = {
    allowUnfreePredicate =
      let
        names = [
          "claude-code"
          "obsbot-sdk"
          "terraform"
        ];
      in
      pkg:
        builtins.elem pkg.pname names
        || builtins.any (n: lib.hasPrefix n (pkg.name or "")) names;

    inherit permittedInsecurePackages;
  };

  home.packages = with pkgs; [
    crane
    buzz-cli
    buzz-desktop
    github-cli-tools
    skopeo
    obsbot-camera-control-cli
    obsbot-camera-control-gui
    stklos
    nautilus
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  sops.secrets.aws-config = {
    format = "yaml";
    key = "aws/config";
    path = "${config.home.homeDirectory}/.aws/config";
  };

  programs.home-manager.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  # Adopt the Firefox state directory used in 26.05 and later
  programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";
}
