{
  lib,
  pkgs,
  ...
}:
{
  # GLib launches Terminal=true desktop entries via xdg-terminal-exec when
  # available (xdg-desktop-portal OpenURI included); without it, portal
  # services fall back to X11 terminals like xterm which cannot open a display
  # on Wayland sessions. See https://github.com/flathub/org.gnome.Boxes/issues/78
  home.packages = lib.mkIf pkgs.stdenv.isLinux [ pkgs.xdg-terminal-exec ];

  xdg.configFile."xdg-terminals.list".text = "com.mitchellh.ghostty.desktop\n";
}
