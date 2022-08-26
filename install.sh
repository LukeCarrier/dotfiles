#!/usr/bin/env bash

default_packages=(
  bash fish zsh
  alacritty starship tmux
  asdf-vm
  git
  openssh
  vim visual-studio-code
)

stow_root="$(cd "$(dirname "$0")" && pwd -P)"
packages=()
while true; do
  case "$1" in
    -p|--package) packages+="$2" ; shift 2 ;;
    *           ) break                    ;;
  esac
done

set -eu -o pipefail

if (( ${#packages[@]} == 0 )); then
  packages=( ${default_packages[@]} )
fi

for package in "${packages[@]}"; do
  echo "Stowing $package to $HOME"
  stow --restow --dir "$stow_root" --target "$HOME" "$package"
done
