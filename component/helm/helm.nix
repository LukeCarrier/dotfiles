{ config, pkgs, lib, ... }:
let
  inherit (pkgs) stdenv;
  inherit (stdenv.hostPlatform) isDarwin;

  mergeConfig = import ../../lib/merge-json-config.nix { inherit pkgs; };

  osStore = if isDarwin then "osxkeychain" else "secretservice";
  realStore = lib.getExe' pkgs.docker-credential-helpers "docker-credential-${osStore}";

  # docker credential-helper name -> binary; extend as credHelpers grows.
  helperBin = {
    ecr-login = lib.getExe' pkgs.amazon-ecr-credential-helper "docker-credential-ecr-login";
  };

  # Helm's OCI client reads credsStore from its registry config but does not act
  # on credHelpers there (verified on helm 3.20.2: with credHelpers present it
  # still invokes only the credsStore, so ECR pulls fail). So make the credsStore
  # a shim that performs Docker's credHelper resolution itself: a host listed in
  # credHelpers goes to its helper, everything else to the OS keychain. The table
  # is generated from the same credHelpers the Docker component writes, so the two
  # cannot drift.
  credHelperCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      host: name: "          ${lib.escapeShellArg host}) helper=${lib.escapeShellArg helperBin.${name}} ;;"
    ) (config.programs.docker-cli.settings.credHelpers or { })
  );
  credStore = pkgs.writeShellScriptBin "docker-credential-credhelpers" ''
    set -euo pipefail

    store=${realStore}

    case "''${1:-}" in
      get)
        url="$(cat)"
        helper=""
        case "$url" in
${credHelperCases}
        esac
        if [ -n "$helper" ]; then
          printf '%s' "$url" | "$helper" get
        else
          printf '%s' "$url" | "$store" get
        fi
        ;;
      *)
        exec "$store" "$@"
        ;;
    esac
  '';

  # Helm's default registry config path (unset HELM_CONFIG_HOME/XDG_CONFIG_HOME).
  registryConfig =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Preferences/helm/registry/config.json"
    else
      "${config.xdg.configHome}/helm/registry/config.json";

  baseConfig = pkgs.writeText "helm-registry-config.json" (builtins.toJSON {
    credsStore = "credhelpers";
  });
in
{
  home.packages = [ credStore ];

  home.activation.helmRegistryConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${mergeConfig}
    mergeJsonConfig "${baseConfig}" "${registryConfig}"
  '';
}
