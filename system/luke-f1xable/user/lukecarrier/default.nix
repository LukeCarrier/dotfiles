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
    ../../../../component/shell-essential/shell-essential.nix
    ../../../../component/fonts/fonts.nix
    ../../../../component/readline/readline.nix
    ../../../../component/kanshi/kanshi.nix
    ../../../../component/gnome-headless/gnome-headless.nix
    ../../../../component/wofi/wofi.nix
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
    ../../../../component/goose/goose.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/agentkit/agentkit.nix
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
    ../../../../component/espanso/espanso.nix
    ../../../../component/ghostty/ghostty.nix
    ../../../../component/rust/cargo.nix
    ../../../../component/aws/aws.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
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
    docker-cli-tools
    skopeo
    monaspace-fonts
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

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        app = "org.gnome.Nautilus";
      in
      {
        "x-scheme-handler/file" = app;
      };
  };

  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
