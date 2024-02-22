#!/usr/bin/env bash

default_packages=(
  readline
  bash fish zsh
  alacritty direnv mcfly starship tmux zoxide
  gnupg
  asdf-vm
  git
  openssh
  helix vim visual-studio-code
  google-cloud-sdk
)

stow_root="$(cd "$(dirname "$0")" && pwd -P)"
force=0
packages=()
while true; do
  case "$1" in
    -f|--force  ) force=1            ; shift 1 ;;
    -p|--package) packages+=( "$2" ) ; shift 2 ;;
    *           ) break                        ;;
  esac
done

if [[ "$USER" == "codespace" ]]; then
  echo "Enabling --force because we're running in Codespaces" >&2
  force=1
fi

set -eu -o pipefail

if ! command -v stow >/dev/null; then
  echo "stow not installed; will attempt installation" >&2
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install stow
  elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    if command -v apt >/dev/null; then
      sudo apt install stow
    else
      echo "Failed to install stow; couldn't detect package manager" >&2
    fi
  else
    echo "Failed to install stow; unknown OS $OSTYPE" >&2
    exit 1
  fi
fi

if (( ${#packages[@]} == 0 )); then
  packages=( ${default_packages[@]} )
fi

for package in "${packages[@]}"; do
  if (( $force != 0 )); then
    echo "Cleaning up any files in $HOME that would conflict with $package"
    find "$stow_root/$package" -type f -exec realpath --relative-to "$stow_root" {} \; \
      | sed -e "s%^%$HOME%" \
      | xargs rm -f
  fi

  echo "Stowing $package to $HOME"
  stow --restow --dir "$stow_root" --target "$HOME" "$package"
done
