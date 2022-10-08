__asdf_vm_find() {
  local arch_aur="/opt/asdf-vm"

  if [[ -f "${arch_air}/asdf.sh" ]]; then
    echo "${arch_aur}/asdf.sh"
  else
    echo "$(brew --prefix asdf)/libexec/asdf.sh"
  fi
}

source "$(__asdf_vm_find)"
unset -f __asdf_vm_find
