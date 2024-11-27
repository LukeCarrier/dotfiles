{ pkgs, ... }:
{
  home.file.".aerospace.toml".source = ./.aerospace.toml;

  targets.darwin.defaults = {
    "com.apple.dock" = {
      expose-group-apps = true;
    };
    "com.apple.spaces" = {
      spans-displays = true;
    };
  };
}
