{ pkgs }:
let
  dockerImageExtract = pkgs.writeShellScriptBin "docker-image-extract" ''
    container_id="$(docker container create "$1")"
    if [[ -n "$2" ]]; then
      docker container cp "$container_id:$2" "$2"
    else
      docker container export "$container_id"
    fi
    docker container rm "$container_id"
  '';
in
pkgs.symlinkJoin {
  pname = "docker-image-extract";
  version = "0.1.0";
  paths = [
    dockerImageExtract
  ];
}
