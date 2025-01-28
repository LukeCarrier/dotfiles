{ pkgs }:
let
  basename = "${pkgs.coreutils}/bin/basename";
  getopt = "${pkgs.getopt}/bin/getopt";
  kubectl = "${pkgs.kubectl}/bin/kubectl";
  parallel = "${pkgs.parallel}/bin/parallel";
  kubectlDrainAll = pkgs.writeShellScriptBin "kubectl-drain-all" ''
    me="$("${basename}" $0)"
    opts="$("${getopt}" -n "$me" -o +l:p: -l label:,parallelism: -- "$@")"
    eval set -- "$opts"

    get_node_args=( )
    parallelism=1
    while true; do
      case "$1" in
        "-l"|"--label")
          get_node_args+=( "-l" "$2" )
          shift 2
          ;;
        "-p"|"--parallelism")
          parallelism="$2"
          shift 2
          ;;
        "--")
          shift
          break
          ;;
        *)
          printf "$me: invalid argument %s" "$1" >&2
          exit 1
          ;;
      esac
    done

    set -eu -o pipefail
    "${kubectl}" get node "''${get_node_args[@]}" -o name \
      | "${parallel}" -j "$parallelism" --line-buffer --tag \
          "${kubectl}" drain "$@"
  '';
in
pkgs.symlinkJoin {
  pname = "kubernetes-client-tools";
  version = "0.1.0";
  paths = [ kubectlDrainAll ];
}
