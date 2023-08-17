__asdf_vm_find() {
  local arch_aur="/opt/asdf-vm"
  local in_home="${HOME}/.asdf"

  if [[ -d "$arch_aur" ]]; then
    echo "${arch_aur}/asdf.sh"
  elif [[ -f "${in_home}/asdf.sh" ]]; then
    echo "${in_home}/asdf.sh"
  else
    echo "$(brew --prefix asdf)/libexec/asdf.sh"
  fi
}

. "$(__asdf_vm_find)"
if [[ -f "${ASDF_DIR}/etc/bash_completion.d/asdf.bash" ]]; then
  . "${ASDF_DIR}/etc/bash_completion.d/asdf.bash"
fi
unset -f __asdf_vm_find
