set -euo pipefail

readonly VAULT="Employee"
readonly FIELD="credential"

item_title() {
  printf 'tofu-%s' "$1"
}

secret_ref() {
  printf 'op://%s/%s/%s' "$VAULT" "$(item_title "$1")" "$FIELD"
}

item_exists() {
  op item get "$(item_title "$1")" --vault "$VAULT" >/dev/null 2>&1 </dev/null
}

read_token() {
  op read "$(secret_ref "$1")" 2>/dev/null || true
}

put_token() {
  local host="$1" token="$2"
  if item_exists "$host"; then
    op item edit "$(item_title "$host")" --vault "$VAULT" \
      "${FIELD}[concealed]=${token}" >/dev/null </dev/null
  else
    op item create \
      --category "API Credential" \
      --title "$(item_title "$host")" \
      --vault "$VAULT" \
      "${FIELD}[concealed]=${token}" >/dev/null </dev/null
  fi
}

delete_item() {
  op item delete "$(item_title "$1")" --vault "$VAULT" >/dev/null 2>&1 || true
}

verb="$1"
host="$2"

case "$verb" in
  get)
    token="$(read_token "$host")"
    if [ -n "$token" ]; then
      printf '{"token":%s}\n' "$(jq -Rn --arg v "$token" '$v')"
    else
      printf '{}\n'
    fi
    ;;

  store)
    # Terraform sends the credentials as a JSON object on stdin.
    token="$(jq -r '.token // empty')"
    if [ -z "$token" ]; then
      echo "no token provided on stdin" >&2
      exit 1
    fi
    put_token "$host" "$token"
    ;;

  forget)
    delete_item "$host"
    ;;

  *)
    echo "unsupported Terraform credentials helper verb: $verb" >&2
    exit 1
    ;;
esac
