function __google_cloud_sdk_find
  set arch_aur "/opt/google-cloud-sdk"

  if test -d $arch_aur;
    echo $arch_aur"/path.fish.inc"
  else
    echo (brew --prefix google-cloud-sdk)"/path.fish.inc"
  end
end

source (__google_cloud_sdk_find)
functions --erase __google_cloud_sdk_find
