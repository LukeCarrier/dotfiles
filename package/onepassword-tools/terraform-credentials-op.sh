set -euo pipefail

secret_ref="$1"
verb="$2"
host="$3"

case "$verb" in
  get)
    token="$(op read "$secret_ref")"
    if [ -n "$token" ]; then
      printf '{"token":%s}\n' "$(jq -Rn --arg v "$token" '$v')"
    else
      printf '{}\n'
    fi
    ;;

  store)
    # Terraform may call this during `terraform login`.
    # Read stdin to satisfy the helper protocol, but do not store.
    cat >/dev/null
    echo "storing credentials via this helper is not supported; update 1Password instead" >&2
    exit 1
    ;;

  forget)
    echo "forget is not supported; remove/update the item in 1Password instead" >&2
    exit 1
    ;;

  *)
    echo "unsupported Terraform credentials helper verb: $verb" >&2
    exit 1
    ;;
esac
