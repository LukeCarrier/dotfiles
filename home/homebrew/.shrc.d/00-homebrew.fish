set cpu_arch (arch)
if [ $cpu_arch = "arm64" ];
  /opt/homebrew/bin/brew shellenv | source
else
  /usr/local/bin/brew shellenv | source
end
set -e cpu_arch
