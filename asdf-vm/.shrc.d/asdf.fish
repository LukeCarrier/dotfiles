function __asdf_vm_find
  set arch_aur "/opt/asdf-vm"

  if test -d $arch_aur;
    echo $arch_aur"/asdf.fish"
  else
    echo (brew --prefix asdf)"/libexec/asdf.fish"
  end
end

source (__asdf_vm_find)
functions --erase __asdf_vm_find
