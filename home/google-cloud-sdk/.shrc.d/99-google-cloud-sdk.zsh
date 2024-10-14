__google_cloud_sdk_find() {
  local arch_aur="/opt/google-cloud-sdk"

  if [[ -d "$arch_aur" ]]; then
    echo "${arch_aur}/path.zsh.inc"
  else
    echo "$(brew --prefix google-cloud-sdk)/path.zsh.inc"
  fi
}

source "$(__google_cloud_sdk_find)"
unset -f __google_cloud_sdk_find
