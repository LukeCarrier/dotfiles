{ config, pkgs, lib, ... }:
let
  inherit (pkgs) stdenv;

  # The credential store maps to a `docker-credential-<store>` binary that
  # Docker invokes to keep registry credentials out of `~/.docker/config.json`.
  # See https://github.com/docker/docker-credential-helpers for details.
  credsStore = if stdenv.isDarwin then "osxkeychain" else "secretservice";

  baseConfig = pkgs.writeText "docker-config.json" (builtins.toJSON (
    { inherit credsStore; }
    // config.programs.docker-cli.settings
  ));

  # Docker stores context metadata at ~/.docker/contexts/meta/<sha256(name)>/meta.json.
  # Compute the paths at eval time so the activation script just does installs.
  contextMeta = lib.mapAttrs' (name: ctx:
    lib.nameValuePair (builtins.hashString "sha256" name)
      (pkgs.writeText "docker-context-${name}-meta.json" (builtins.toJSON {
        Name = name;
        Metadata = { };
        Endpoints.docker = {
          Host = ctx.Endpoints.docker.Host;
          SkipTLSVerify = false;
        };
      }))
  ) config.programs.docker-cli.contexts;
in
{
  home.packages = with pkgs; [
    docker-cli-tools
    docker-credential-helpers
  ];

  # Don't use programs.docker-cli — it symlinks ~/.docker/config.json to the Nix
  # store (read-only), which breaks `docker context use` with a cross-device link
  # error when Docker tries to atomically replace the file. Instead, write a real
  # mutable file at activation and merge our managed fields on top so Docker can
  # modify it freely (e.g. currentContext).
  home.activation.dockerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.docker/config.json"
    base="${baseConfig}"

    $DRY_RUN_CMD mkdir -p "$HOME/.docker"

    if [ -L "$target" ]; then
      $DRY_RUN_CMD unlink "$target"
    fi

    if [ -f "$target" ]; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq --slurpfile base "$base" '. * $base[0]' "$target" > "$tmp"
      chmod 644 "$tmp"
      $DRY_RUN_CMD mv -f "$tmp" "$target"
    else
      $DRY_RUN_CMD install -m 644 "$base" "$target"
    fi

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (hash: metaFile: ''
      $DRY_RUN_CMD mkdir -p "$HOME/.docker/contexts/meta/${hash}"
      $DRY_RUN_CMD install -m 644 "${metaFile}" "$HOME/.docker/contexts/meta/${hash}/meta.json"
    '') contextMeta)}
  '';
}
