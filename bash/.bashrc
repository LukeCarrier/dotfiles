for f in "$HOME"/.shrc.d/*.sh; do
  . "$f"
done
for f in "$HOME"/.shrc.d/*.bash; do
  . "$f"
done

set -o vi
