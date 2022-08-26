#!/usr/bin/env bash

default_packages=(
  bash fish
  alacritty starship tmux
  git
  vim visual-studio-code
)

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
  stow --restow --target "$HOME" "$package"
done
