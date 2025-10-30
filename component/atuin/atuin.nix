{ config, pkgs, ... }:

let
  inherit (pkgs) lib;
in
{
  programs.atuin = {
    enable = true;
    settings = {
      enter_accept = false;
      filter_mode = "host";
      filter_mode_shell_up_key_binding = "session";
      keymap_mode = "vim-insert";
    };

    enableFishIntegration = false;
  };

  # atuinsh/atuin#2803
  programs.fish.interactiveShellInit =
    let
      flagsStr = lib.escapeShellArgs config.programs.atuin.flags;
    in
    ''
      ${lib.getExe pkgs.atuin} init fish ${flagsStr} | sed 's/-k up/up/' | source
    '';
}
