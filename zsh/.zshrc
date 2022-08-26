for f in "$HOME"/.shrc.d/*.sh; do
  . "$f"
done
for f in "$HOME"/.shrc.d/*.zsh; do
  . "$f"
done

bindkey -v
