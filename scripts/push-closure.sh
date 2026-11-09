#!/usr/bin/env bash
set -euo pipefail

# Copy a store path and its closure to a remote machine over SSH.
#
# Usage: push-closure.sh <[user@]host> <store-path>
#
# Tries an unprivileged `nix copy` first, which requires the remote user to be
# in the remote `nix.settings.trusted-users`. When that is refused, imports the
# closure as root instead. The NAR stream and sudo's password prompt cannot
# share stdin, so the import reads from a FIFO while the importer keeps the
# terminal for the password prompt. Run interactively for that fallback.

target=$1
closure=$2

if nix copy --to "ssh-ng://$target" "$closure"; then
  exit 0
fi

echo "unprivileged copy refused; importing $closure as root via sudo" >&2

if [ -t 0 ]; then
  tty_input=/dev/stdin
elif { : </dev/tty; } 2>/dev/null; then
  tty_input=/dev/tty
else
  echo "push-closure: the sudo fallback needs a terminal; run interactively or add" >&2
  echo "push-closure: the remote user to nix.settings.trusted-users" >&2
  exit 1
fi

fifo=$(ssh "$target" 'mktemp -u "${TMPDIR:-/tmp}/nix-push.XXXXXXXX"')
ssh "$target" "mkfifo '$fifo'"

# The writer's stdin is the pipe, so backgrounding does not break it. The
# importer stays in the foreground so sudo can prompt on the terminal.
nix-store --query --requisites "$closure" \
  | xargs -r nix-store --export \
  | ssh "$target" "cat > '$fifo'" &
writer_pid=$!
trap 'kill "$writer_pid" 2>/dev/null || true' EXIT

ssh -t "$target" "sudo nix-store --import < '$fifo'; rc=\$?; rm -f '$fifo'; exit \$rc" <"$tty_input"

wait "$writer_pid"
trap - EXIT
