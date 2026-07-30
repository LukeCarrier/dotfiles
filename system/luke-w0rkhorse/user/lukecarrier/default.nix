{
  config,
  lib,
  pkgs,
  inputs,
  permittedInsecurePackages,
  ...
}:
let
  inherit (lib) getExe';
in
{
  imports = [
    inputs.niri.homeModules.niri
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.sops-nix.homeManagerModules.sops
    ../../../../employer/emed/emed.nix
    ../../../../component/docker/docker.nix
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
    ../../../../component/1password/1password.nix
    ../../../../component/handy/nixos-home.nix
    ../../../../component/goose/goose.nix
    ../../../../component/opencode/opencode.nix
    ../../../../component/claude-code/claude-code.nix
    ../../../../component/codex/codex.nix
    ../../../../component/handy/nixos-home.nix
    ../../../../component/openssh/openssh.nix
    ../../../../component/atuin/atuin.nix
    ../../../../component/starship/starship.nix
    ../../../../component/tmux/tmux.nix
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
    ../../../../component/helm/helm.nix
    ../../../../component/kubernetes-client/kubernetes-client.nix
  ];

  home = {
    stateVersion = "26.05";

    username = "lukecarrier";
    homeDirectory = "/home/lukecarrier";
  };

  sops.defaultSopsFile = ../../../../secrets/employer-emed.yaml;

  nixpkgs.config = {
    allowUnfreePredicate =
      let
        names = [
          "1password"
          "1password-cli"
          "onepassword-password-manager"

          "cursor"
          "cursor-cli"

          "claude-code"
          "obsbot-sdk"
          "terraform"
        ];
      in
      pkg: builtins.elem (lib.getName pkg) names;

    inherit permittedInsecurePackages;
  };

  home.packages = with pkgs; [
    crane
    skopeo
    hibiki
    obsbot-camera-control-cli
    obsbot-camera-control-gui
    nautilus
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/Code/LukeCarrier/dotfiles/.sops/keys";

  programs.mcp.servers.excalidraw = {
    command = getExe' pkgs.excalidraw-mcp-app "excalidraw-mcp-app";
    args = [ "--stdio" ];
  };

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

  fonts.fontconfig.hinting = lib.mkForce "slight";

  xdg.configFile."fontconfig/conf.d/10-subpixel.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="font">
        <edit name="rgba" mode="assign"><const>rgb</const></edit>
        <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
      </match>
    </fontconfig>
  '';
}
