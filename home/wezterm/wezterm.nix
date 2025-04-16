{ pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    # On macOS we expect the app bundle in /Applications, installed via
    # Homebrew cask or manually. Lots of things seem broken using the nixpkgs
    # executable, and it's harder to launch.
    package = (
      if pkgs.stdenv.isDarwin
      then (
        pkgs.runCommand "wezterm-darwin" {
        } ''
          mkdir -p "$out/bin"
          ln -sf "/Applications/WezTerm.app/Contents/MacOS/wezterm" "$out/bin/wezterm"
        ''
      )
      else pkgs.wezterm
    );
    enableBashIntegration = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ./.wezterm.lua;
  };
}
