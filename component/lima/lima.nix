{ config, pkgs, ... }:
let
  sock = vm: "unix://${config.home.homeDirectory}/.lima/${vm}/sock/docker.sock";
in
{
  home.packages = with pkgs; [
    docker-client
    docker-credential-helpers
    lima
  ];

  home.file = {
    ".lima/docker-amd64/lima.yaml".source = ./.lima/docker-amd64/lima.yaml;
    ".lima/docker-amd64-rosetta/lima.yaml".source = ./.lima/docker-amd64-rosetta/lima.yaml;
    ".lima/docker-arm64/lima.yaml".source = ./.lima/docker-arm64/lima.yaml;
  };

  programs.ssh.includes = [ "~/.lima/*/ssh.config" ];

  programs.docker-cli.contexts = {
    lima-docker-amd64.Endpoints.docker.Host = sock "docker-amd64";
    lima-docker-arm64.Endpoints.docker.Host = sock "docker-arm64";
    lima-docker-amd64-rosetta.Endpoints.docker.Host = sock "docker-amd64-rosetta";
  };
}
