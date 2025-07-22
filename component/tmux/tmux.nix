{ config, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    tmuxinator.enable = true;

    plugins = with pkgs.tmuxPlugins; [
      logging
      yank
      power-theme
    ];

    prefix = "C-Space";

    keyMode = "vi";
    mouse = true;

    extraConfig = ''
      # Work around nix-community/home-manager#5952
      set -gu default-command
      set -g default-shell "${config.programs.tmux.shell}"

      # Deal with broken terminfo
      set  -g default-terminal tmux-256color
      set -ag terminal-overrides ",$TERM:RGB"

      # Clear the scrollback
      bind C-k 'send-keys -R C-l; clear-history'

      # Don't exit copy mode after making a selection
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection -x

      # Let tmux handle scroll events
      set -g terminal-overrides 'xterm*:smcup@:rmcup@'

      # Make the bell visual, not audible
      setw -g visual-bell on
      setw -g bell-action other

      # Light bit of UI
      set -g @tmux_power_theme 'snow'
      set -g pane-border-status top
      set -g pane-border-format " [ (#P) #T ] "
    '';
  };
}
