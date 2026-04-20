{
  config,
  lib,
  pkgs,
  inputs,
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
    ../../../../component/waybar/waybar.nix
    ../../../../component/hyprcursor/hyprcursor.nix
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
    ../../../../component/ollama/ollama.nix
    ../../../../component/goose/goose.nix
    ../../../../component/opencode/opencode.nix
    # ../../../../component/gnome-network-displays/home.nix
    ../../../../component/valent/home.nix
    ../../../../component/bitwarden/bitwarden.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
    ../../../../component/coder/coder.nix
    ../../../../component/helix/helix.nix
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
    stateVersion = "25.11";

    username = "lukecarrier";
    homeDirectory = "/home/lukecarrier";
  };

  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "terraform"
        "cuda_cccl"
        "cuda_cudart"
        "cuda_merged"
        "cuda_nvcc"
        "cuda_nvrtc"
        "cudnn"
        "libcublas"
        "libcufft"
        "libcurand"
        "libcusparse"
        "libnvjitlink"
      ];
    cudaSupport = true;
  };

  home.packages = with pkgs; [
    crane
    docker-cli-tools
    skopeo
    handy
    monaspace-fonts
    nautilus
    ungoogled-chromium
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  sops.secrets.aws-config = {
    sopsFile = ../../../../secrets/personal.yaml;
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
