for f in "$HOME"/.shrc.d/*.sh; do
  . "$f"
done
for f in "$HOME"/.shrc.d/*.bash; do
  . "$f"
done

if [[ $- == *i* ]]; then
  set -o vi
fi
