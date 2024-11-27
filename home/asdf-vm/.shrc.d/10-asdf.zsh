__asdf_vm_find() {
  local arch_aur="/opt/asdf-vm"
  local in_home="$HOME/.asdf"

  if [[ -f "${arch_aur}/asdf.sh" ]]; then
    echo "${arch_aur}/asdf.sh"
  elif [[ -f "${in_home}/asdf.sh" ]]; then
    echo "${in_home}/asdf.sh"
  else
    echo "$(brew --prefix asdf)/libexec/asdf.sh"
  fi
}

source "$(__asdf_vm_find)"
unset -f __asdf_vm_find
