function __asdf_vm_find
  set arch_aur "/opt/asdf-vm"
  set in_home $HOME"/.asdf"

  if test -d $arch_aur;
    echo $arch_aur"/asdf.fish"
  else if test -f $in_home"/asdf.sh";
    echo $in_home"/asdf.sh"
  else
    echo (brew --prefix asdf)"/libexec/asdf.fish"
  end
end

source (__asdf_vm_find)
functions --erase __asdf_vm_find
