__google_cloud_sdk_find() {
  local arch_aur="/opt/google-cloud-sdk"

  if [[ -d "$arch_aur" ]]; then
    echo "${arch_aur}/path.bash.inc"
  else
    echo "$(brew --prefix google-cloud-sdk)/path.bash.inc"
  fi
}

source "$(__google_cloud_sdk_find)"
unset -f __google_cloud_sdk_find
