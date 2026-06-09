{ pkgs, ... }:
let
  inherit (pkgs) stdenv;

  # The credential store maps to a `docker-credential-<store>` binary that
  # Docker invokes to keep registry credentials out of `~/.docker/config.json`.
  # See https://github.com/docker/docker-credential-helpers for details.
  credsStore = if stdenv.isDarwin then "osxkeychain" else "secretservice";
in
{
  home.packages = with pkgs; [
    docker-cli-tools
    docker-credential-helpers
  ];

  programs.docker-cli = {
    enable = true;
    settings = {
      inherit credsStore;
    };
  };
}
