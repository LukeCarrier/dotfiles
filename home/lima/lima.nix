{ pkgs, ... }:
{
  home.packages = with pkgs; [ lima ];

  home.file.".lima/docker-amd64/lima.yaml".source = ./.lima/docker-amd64/lima.yaml;
  home.file.".lima/docker-amd64-rosetta/lima.yaml".source = ./.lima/docker-amd64-rosetta/lima.yaml;
  home.file.".lima/docker-arm64/lima.yaml".source = ./.lima/docker-arm64/lima.yaml;
}
